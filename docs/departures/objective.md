# Departures: objective

Where `src/fn/objective/` differs from `BotObjective.cs`, `BotGoalSpot.cs`,
`BotRoles.cs` and `SpawnPoints.cs`, and why.

## World state is the game's instances

- **Dual KotH is `instance_exists(DKothHUD)`**, not `WorldState.GameMode`. The
  real game never stores a mode; `basicRoomSetup` creates `DKothHUD` for exactly
  the layout the C# calls `DualKingOfTheHill` (both `KothRedControlPoint` and
  `KothBlueControlPoint`, no single-hill or arena point). The C# reads the mode
  here and nowhere else, and so does this.
- **A capture zone's centre is its instance's `bbox`**, and a zone belongs to
  whichever point its own `cp` names (`instance_nearest` in its Alarm 0) - the
  game's binding, which `ControlPoints.Place` reproduces. GM8's `bbox_right/bottom`
  are inclusive, so a centre may sit half a pixel from the C#'s.
- **A generator's middle is its instance's `bbox`** rather than
  `Generators.BodyBox`, the box GM8 itself reports; same half-pixel caveat.
- **Points are visited in instance order** (`instance_find(ControlPoint, i)`),
  where the C# uses `ControlPoints.Place`'s index order. Only a tie in distance
  could tell them apart.
- **The carrier and the TDM quarry are `Character` instances**, found with
  `with (Character)`, where the C# returns slots. Team is `Character.team` (copied
  from `player.team` at Create; a team change kills the character). The first of
  equals is the first in instance order rather than the lowest slot.
- **Spawn points come from the game's own table**, `global.spawnPointsRed/Blue`
  (offloadSpawnPoints), rather than from map entities. It is the table
  `doEventSpawn` resolves a `PLAYER_SPAWN` against - what `SpawnPoints` models -
  and it already excludes other map areas.

## GM8 limits

- **`botGoalSpotFind` takes the NavQuery as one bitmask** (`BOT_SPOT_Q_*`): the
  C#'s parameter list is 20 arguments with the query spread out, and a GML
  function takes 16. The collision world and filter are dropped (the sightline is
  the game's `collision_line_bulletblocking`). The team bit is "blue"; anything
  not blue is red, which only differs for a spectator, who has no character.
- **Candidate order is a `ds_priority`** keyed on `rank + node * BOT_SPOT_TIE_EPS`
  (1e-6), where the C# sorts with a node-index tie-break. GM8 has no sort with a
  comparator, and a ds_priority's own tie order is unspecified; the epsilon can
  only reorder two ranks within 0.001 px of each other.
- **`navGraphEdgeRoutable` is inlined in `botGoalSpotReach`.** `NavGraph`
  insists on one copy of that rule, but here it is evaluated once per edge of a
  whole-graph BFS, and an interpreted function call per edge roughly doubles a
  pass that already runs on most decisions of a walking bot. The inlined copy is
  `GatePassable` (`charSetSolids`) plus the three class-arc refusals, verbatim;
  it must change whenever nav's does.
- **No NaN, no `?`**: `C# int? target` is `noone`; `Team? chase` is -1.

## Structure

- **Per-map state is a generation counter**, not a fresh object. The C# builds a
  `BotObjective` (and its `BotGoalSpot`) per bot per map; here the graph is
  global, `botSpawnsLoad` bumps `global.botSpawnsGen`, and a bot's held spot node
  and the reach cache are dropped when their generation is stale.
- **The reach cache is shared by every bot**, keyed on (from node, query, map
  generation, node count), where the C# keeps one per bot. The answer depends on
  nothing else, so sharing changes no result and only adds cache hits.
- **The ranking pass walks only the mask rows that can be in the band.** The band
  is a distance from the anchor, so a node whose stand height is more than
  `maxDistance` from it cannot qualify; nodes are stored sorted by row, so the
  pass starts at `botNavRowStart` of the lowest such row and stops past the
  highest. Same candidates in the same order; the C# scans every node. (The
  widening fallback still scans every node, as the C#.)
- **`target` and the medic's ally may be a `Player` or a `Character`**, tested by
  `object_index`, so the call does not depend on which the combat module returns.
- **Without a nav graph** (`global.botNavReady` false) the cascade still runs and
  returns a goal, the spot search answers "nothing" (so the goal is the
  objective's own point), and `botObjectiveTryResolve` returns false. The C#
  always has a graph.
- `BotGoalSpot.Tries` is `global.botGoalSpotTries`.
