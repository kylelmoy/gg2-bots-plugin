# path: departures from the C#

`BotPathState`, `PathFollower`, `JumpModel`, `RocketModel`, `StickyModel`,
`BotArc`. Behaviour is the C#'s throughout; what follows is how the GML gets
there differently, and the few places a game variable stands in for a
gg2-server table.

## State and structure

- **`Blacklist` + `BlacklistOrder` are a ds_map (key -> expiry) and a ds_queue
  of keys**, where the C# has a `HashSet<long>` and a `List<(Key, Expiry)>`.
  The sweep reads the expiry of the queue's head from the map. Same order,
  same comparison (`> tick` survives), same not-re-armed rule.
- **`PlanQuery` is six fields** (`botPathPlanQuery<Field>`), and the default
  `NavQuery` it starts as is team `TEAM_RED` (`default(Team)`) with every flag
  false.
- **`ReplanStagger` defaults to the Player's instance id**, which is what the
  reference GML used (`botPathPlan.gml:53`), rather than the roster slot the
  C# passes - roster slots compact here (PORTING.md, "Identity"). It is still
  taken `mod BOT_REPLAN_TICKS` at use, so the interval stays in [45, 89].
- **`Path.AddRange(_scratch)` is `ds_list_copy`** after `FreePath` - the same
  result, one native call.
- **`PathFollower.Steering` (a private struct passed by `ref`) is a set of
  globals**, `global.botFollowerSteer<Field>`, reset to `default(Steering)` at
  the top of `botFollowerFollowEdge`. Only that call and the functions it calls
  touch them, and none of them re-enters the follower for another bot.
- **`Approach`, `SteerFall` and `Press` are inlined** into their only callers
  (marked in the source): each is a few lines run every tick, and a function
  call is the expensive thing in interpreted GML. `Gate`, `Launch`,
  `FloorUnder` and `TryFindEdge` stay functions.
- **`Gate` re-reads `needVx` and `flightTicks` off the edge** instead of taking
  them as parameters: with the six query arguments it would need seventeen,
  and GM8 stops at sixteen. Same values.
- **`Lane` is `player.botFollowerLane`**, whatever handle `navSearchFind` takes
  (-1 = the graph's own costs); **`Distances` is not per bot** - the tables
  are nav's one shared set and `navSearchFind` is assumed to apply them
  (docs/path.md, "Assumptions about nav").
- **`occupancy` is never null**: the C#'s `BotOccupancy?` is always passed
  (`botOccupancyAdd/Remove`, and `true` to `navSearchFind`). A server that
  turns occupancy off does it inside nav.
- **`tick` is `global.botTick`**, not a parameter (PORTING.md).

## Calls the C# guards by construction

- **`botFollowerStep` returns no keys when `!global.botNavReady`**, after
  clearing the four launch requests. The C# never calls `Step` without a
  graph (`ScriptedBot`: `_graph is null ? None : Step(...)`); this is the same
  answer from inside, and stops a stale request reaching `ApplyLaunch`.
  `botFollowerSetGoal` likewise returns false (`ScriptedBot.SetGoal`).
- **There is no weaponless `Step` overload.** The weapon is always
  `char.currentWeapon`; a `-1` weapon answers "not capable, not ready", which
  is what the C#'s zeroed `WeaponState` answers.
- **`TryFindEdge` bounds-checks `from`** against `global.botNavNodeCount`
  (the C#'s `EdgesFrom` does the same and returns the empty slice).

## Game variables standing in for gg2-server tables

- **`WeaponStats.KindFor(class) == Rocketlauncher` / `Minegun` is asked of the
  weapon** (`char.currentWeapon.object_index`), not of the class. A
  character's `currentWeapon` is its class's `weapons[0]`, so the answer is
  the same; asking the weapon also guarantees `ammoCount`/`readyToShoot` are
  read off the right object.
- **`JumpModel.Reach`'s control factor** is `CharacterPhysics.ControlAndFriction`
  computed from `char.moveStatus` exactly as Begin Step's switch does (0.65,
  0.45, 0.35, `baseControl`, `baseControl - 0.2` humiliated, `- 0.1` intel)
  - deliberately not `char.controlFactor`, which is last Begin Step's value and
  can lag a `moveStatus` change made later in the tick. Max speed and friction
  are `char.basemaxspeed` / `char.baseFriction`, which Character's Create
  derives from the same numbers as `ClassStats`.
- **`FloorUnder`'s `CollisionWorld.IsSolidAt`** (walkmask only) is
  `collision_point(x, y, CustomMapO, true, true)`. The C#'s `Collision` is
  optional and null keeps the old straight-down aim; `ScriptedBot` always sets
  it, so here the terrain is always asked.
- **`BotArc.Clear`** tests each of its ten segments with the game's own
  `collision_line_bulletblocking` (Obstacle, BulletWall, IntelGate, TeamGate
  unless the map is changing, setup gates while closed), where the C# filters
  `CollisionFilter.ForBullet`'s rects once for the whole parabola and then
  tests the segments. Same samples, same answer up to the game's definition of
  what blocks a bullet, which is the authority.
