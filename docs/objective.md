# The objective module

`BotObjective`, `BotGoal`, `BotGoalSpot`, `BotRoles` (gg2-server `src/GG2.Bots/`)
and `SpawnPoints` (`src/GG2.Maps/`), in `src/fn/objective/`. Constants in
`src/constants/objective.txt`; departures from the C# in
`docs/departures/objective.md`.

## Signatures

```
botObjectiveDecide(player, role, spreadX, allowSpot, target, reposting, repostSkip,
                   repostNearBot, useReachable, team, hasIntel, setupGatesClosed,
                   canDoubleJump, canRocketJump, canStickyJump)
    -> global.botRet           BotGoal.Found
       global.botRetX          BotGoal.X
       global.botRetY          BotGoal.Y
       global.botRetIsSpot     BotGoal.IsSpot
       global.botRetMustTouch  BotGoal.MustTouch
       global.botRetOffset     BotGoal.Offset
    (all 0/false when Found is false)

botObjectiveTryResolve(player, found, x, y, isSpot, mustTouch, offset)
    -> global.botRet (bool), global.botRetX, global.botRetY

botObjectiveInit(player)     per-bot fields, once when the bot joins
botObjectiveFree(player)     nothing to free; present for symmetry

botSpawnsLoad()              after every map load, once global.botNavReady is true
botSpawnsCount(team, group)  -> count
botSpawnsTryGet(team, group, index) -> bool, global.botRetX / botRetY

botRolesAssign(class, earlierDsList)    -> BOT_ROLE_ATTACK / BOT_ROLE_DEFEND
botRolesAssignPlace(class, placeInGroup) -> role (the C# int overload)
botRolesSpreadX(stagger)                -> lateral offset, px
botRolesLane(placeInTeam, lanes)        -> lane index

botGoalSpotFind(fromX, fromY, targetX, targetY, minDistance, maxDistance, los,
                highBonus, avoidRadius, avoidNode, skip, stickyNode, fromNode, query)
    -> global.botRet = node or -1, global.botRetX / botRetY (the anchor on a miss)
       global.botGoalSpotTries (BotGoalSpot.Tries)
botGoalSpotReach(fromNode, query)       the reachability BFS Find uses
```

`botObjectiveDecide`'s arguments, in the C#'s order:

| arg | C# | GML |
|---|---|---|
| player | `slot` | the bot's `Player` |
| role | `BotRole role` | `BOT_ROLE_ATTACK` / `BOT_ROLE_DEFEND` (generated.txt) |
| spreadX | `double spreadX` | `botRolesSpreadX(...)`, constant for the bot's life |
| allowSpot | `bool allowSpot` | false while the caller bans spot goals |
| target | `int? target` | the combat half's target: its `Player` (a `Character` is accepted too) or `noone` |
| reposting, repostSkip, repostNearBot | same | the caller's re-post state |
| useReachable + six | `NavQuery? reachableFor` | `false` = null; then `team, hasIntel, setupGatesClosed, canDoubleJump, canRocketJump, canStickyJump` (PORTING.md's NavQuery order). Ignored when `useReachable` is false. |

`botRolesAssign`'s list is the classes (game `CLASS_*` values) of this team's
**bots** that come before this one on the roster, in roster order; the caller
builds and frees it. `botRolesSpreadX`'s `stagger` is any stable small integer
identifying the bot (the C# uses the roster slot).

`botGoalSpotFind`'s `los` is `BOT_LOS_ANY/NEED/AVOID`; `query` is the NavQuery
packed into `BOT_SPOT_Q_*` bits (objective.txt), or -1 for "no query".

## State

Per bot, on the `Player` (all set by `botObjectiveInit`):

| field | C# |
|---|---|
| `botObjectiveSpotNode` | `_spotNode` (-1 none) |
| `botObjectiveSpotAnchorX`, `botObjectiveSpotAnchorY` | `_spotAnchorX/Y` |
| `botObjectiveSpotMin`, `botObjectiveSpotMax`, `botObjectiveSpotHigh` | `_spotMin/_spotMax/_spotHigh` |
| `botObjectiveSpotLos` | `_spotLos` |
| `botObjectiveSpotGen` | the map generation the node belongs to (no C# field: a fresh `BotObjective` per map) |

Shared:

| global | what |
|---|---|
| `global.botSpawnsGrid` | ds_grid 4 x n: team, group, x, y; red groups 0..4 then blue |
| `global.botSpawnsN` | rows in use |
| `global.botSpawnsGen` | map generation, +1 per `botSpawnsLoad` |
| `global.botGoalSpotReachGrid`, `global.botGoalSpotQueue`, `global.botGoalSpotReach{From,Query,Gen,Count}` | the reach BFS's scratch and cache key (created on first use) |
| `global.botGoalSpotTries` | sightline tests the last Find paid for |

## Game state read

Every variable below exists in the game source (checked against
`D:/Code/Gang-Garrison-2/Source/gg2/Objects/**`).

| C# | GML |
|---|---|
| `Intel.HasBase` | `instance_exists(IntelligenceBaseRed/Blue)` (parent `IntelligenceBase`); home = its `x`, `y` |
| `Intel.OnField`, `X`, `Y` | `instance_exists(IntelligenceRed/Blue)` (parent `Intelligence`); a carried flag has no instance |
| `CharacterState.CarryingIntel` | `Character.intel` |
| carrier's team | `Character.team` (set from `player.team` at Create; a team change kills the character) |
| `Generator.Exists`, `BodyBox` | `instance_exists(GeneratorRed/Blue)`, its `bbox_*` |
| `ControlPointState.Owned/Team` | `ControlPoint.team` (-1 = nobody) |
| `.Locked`, `.RedPresence`, `.BluePresence`, `.Capping`, `.BeingCaptured/.CappingTeam` | `.locked`, `.redPresence`, `.bluePresence`, `.capping`, `.cappingTeam` (-1 = nobody) - all set by `ControlPoint`'s User Event 0, which every child's Create inherits |
| `CaptureZone.Point` | `CaptureZone.cp` (its Alarm 0: `instance_nearest(x, y, ControlPoint)` or the `ArenaControlPoint`) |
| `GameMode == DualKingOfTheHill` | `instance_exists(DKothHUD)` (basicRoomSetup creates it for that layout) |
| index 0 / 1 of a DKOTH map | `KothRedControlPoint` / `KothBlueControlPoint` |
| `SpawnPoints` | `global.spawnPointsRed/Blue[0 (x) / 1 (y), group]`, offloadSpawnPoints' ds_lists |
| `Player.Team`, `.Class` | `player.team`, `player.class` |
| sightline (`CollisionLineBlocksBullets` + `ForBullet`) | the game's `collision_line_bulletblocking` |

The nav graph is read directly (`global.botNavNodes`, `botNavEdges`,
`botNavEdgeStart`, `botNavRowStart`, `botNavNodeCount`, `botNavReady`), per
PORTING.md.

## Calls into other modules

| call | assumed signature |
|---|---|
| `navGraphNodeFromWorld(x, y)` | node in `global.botRet`, -1 if none |
| `navGraphSnapObjective(x, y)` | `NavSnap`: `Node` in `global.botRet` (PORTING.md) |
| `botAllyFind(player, range, skipFollowers)` | `BotAlly.Find`: the ally's `Player`, or `noone` |
| `botClassProfileFollows(class)`, `botClassProfileSpotMode(class)` (`BOT_SPOT_*`), `botClassProfileSpotHigh(class)`, `botClassProfileDefendEvery(class)` | game `CLASS_*` value in, the C# value out |
| `botTargetingClassRange(class)`, `botTargetingClassMinBand(class)` | same |

### Assumptions about other modules

- `botAllyFind` returns the ally's **`Player`** instance (the literal translation
  of a slot) and `noone` (or -1) for `BotAlly.None`. `botObjectiveDecide` also
  accepts a `Character` instance there (it tests `object_index == Player`), so
  either choice works.
- The combat target passed as `target` likewise may be a `Player` or a
  `Character`; a destroyed instance or a dead player reads as "no target".
- `botClassProfile*`/`botTargeting*` take `player.class` (the game's `CLASS_*`).
- `navGraphSnapObjective` and `navGraphNodeFromWorld` are only called while
  `global.botNavReady` is true.
- `global.botNavReady` exists (as false) before any bot can think.
- The nav graph's nodes are sorted by row ascending and `global.botNavRowStart[0, row]`
  is the first node on that row (NavGraph `_rowStart`), which `botGoalSpotFind`'s
  row pruning relies on.
- **`navGraphEdgeRoutable` is inlined in `botGoalSpotReach`** for speed (one
  test per edge of a whole-graph BFS); the two must agree. See the departures file.

## For the integrator

- Call `botSpawnsLoad()` after every map load once `global.botNavReady` is
  true. Without it, `NearestEnemySpawn` has no spawns (no push, no engineer
  chokepoint offset) and a held spot node is not invalidated across the map
  change (it is still range-checked against the node count).
- `botObjectiveDecide` is the C#'s `Decide` and nothing more: the 30-tick
  cadence, the spot ban (`allowSpot`), the re-post bookkeeping, the retarget
  throttle (`BOT_GOAL_RETARGET_DIST`) and issuing the goal belong to the caller
  (`ScriptedBot`), as in the C#.
- Hand the goal to `botObjectiveTryResolve` field by field, then issue
  `global.botRetX/Y`.
- Verify live: a CTF carry and return; a defender standing beside (not on) its
  flag; a KotH bot walking out during the pregame lock; a Dual KotH attacker on
  the enemy hill; a TDM bot standing off its target; an engineer's chokepoint
  spot; that `botGoalSpotFind` + `botGoalSpotReach` stay cheap with a full server
  (watch fps on cp_dirtbowl, the largest graph).
