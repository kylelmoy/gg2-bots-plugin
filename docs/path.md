# path: the route follower

`BotPathState`, `PathFollower` (all three files), `JumpModel`, `RocketModel`,
`StickyModel` and `BotArc` from `D:/Code/gg2-server/src/GG2.Bots/`, as
`src/fn/path/`. Constants in `src/constants/path.txt`; where the GML differs
from the C#, `docs/departures/path.md`.

## Assumptions about nav

Written while nav was being ported in parallel; the integrator reconciles
these against what nav actually wrote. Every call below is a whole statement
and reads its extra results immediately.

| call | assumed signature and meaning |
|---|---|
| `navGraphNodeFromWorld(x, y)` | `NavGraph.NodeFromWorld`: node index or -1. |
| `navGraphSnapObjective(x, y)` | `NavGraph.SnapObjective`: node in `global.botRet` (-1 if none), the snapped stand position in `global.botRetGoalX` / `global.botRetGoalY` (PORTING.md). |
| `navGraphEdgeRoutable(edge, team, hasIntel, setupGatesClosed, canDoubleJump, canRocketJump, canStickyJump)` | `NavGraph.EdgeRoutable(in NavEdge, in NavQuery)`. **`edge` is the edge's row in `global.botNavEdges`**, not a struct. Returns bool. Called once per parallel candidate every follower tick, so it should be cheap. |
| `navGraphEdgePassable(edge, team, hasIntel, setupGatesClosed)` | `NavGraph.EdgePassable`, `edge` again a row index. Returns bool. Only called when a run-up is started. |
| `navGraphEdgeKey(from, to)` | `NavGraph.EdgeKey`: `from * 100000 + to`. Used for the blacklist's keys. |
| `navSearchFind(start, goal, team, hasIntel, setupGatesClosed, canDoubleJump, canRocketJump, canStickyJump, pathList, blacklistMap, occupancyFlag, laneCostsOrMinus1, plan)` | `NavSearch.Find`. Clears `pathList` (a ds_list) and fills it with the route's node indices, start to goal; returns bool. `blacklistMap` is `player.botPathBlacklist`: a ds_map whose **keys** are the banned edge keys (the values are expiry ticks and mean nothing to the search). `occupancyFlag` is always passed `true`, meaning "price with the occupancy counts for `team`" (C#: `occupancy?.Counts(query.Team)`; nav owns any server switch that turns occupancy off). `laneCostsOrMinus1` is `player.botFollowerLane` passed through verbatim. `plan` is `BOT_FOLLOWER_NAV_PLAN` = 0 = `NavPlan.DecideByCrowd`. **Distances are not passed**: `Distances?.For(query)` is assumed to be applied by `navSearchFind` itself from nav's shared tables when they are loaded and enabled. |
| `botOccupancyAdd(player, team)` | `BotOccupancy.Add(state, team)`: reads `player.botPathPath`, writes `player.botPathOccupiedTeam` (fewer than 2 nodes: set it to `TEAM_SPECTATOR` and count nothing; already occupied: no-op). **Passed the query's team as a second argument**, as the C# does; if nav's version takes only `player`, the extra argument is harmless, but it should count against the team passed (identical to `player.team` in practice). |
| `botOccupancyRemove(player)` | `BotOccupancy.Remove(state)`: idempotent, against `player.botPathOccupiedTeam`, through the still-installed `player.botPathPath`. |

Read directly (PORTING.md's layout): `global.botNavReady`,
`global.botNavNodes` (`NAV_NODE_X0`, `NAV_NODE_X1`), `global.botNavEdges`
(`NAV_EDGE_TO`, `_TYPE`, `_BUCKET`, `_TICKS`, `_COST`, `_TAKEOFF`, `_REJUMP`),
`global.botNavEdgeStart` (`[0, n]` first edge or -1, `[1, n]` count),
`global.botNavNodeCount`. `NavGraph.AnchorColumn` and `ColumnWorldX` are
inlined as their formulas.

## Exposed functions

Calls are whole statements (PORTING.md). "q6" is the NavQuery as six
arguments: `team, hasIntel, setupGatesClosed, canDoubleJump, canRocketJump,
canStickyJump`.

| function | C# | returns |
|---|---|---|
| `botPathInit(player)` / `botPathFree(player)` | `new BotPathState` / (frees its ds_) | - |
| `botPathFreePath(player)` | `BotPathState.FreePath` | - |
| `botPathBlacklistEdge(player, from, to)` | `BotPathState.BlacklistEdge` (tick = `global.botTick`) | - |
| `botPathSweepBlacklist(player)` | `BotPathState.SweepBlacklist` | - |
| `botPathHasPath(player)` | `BotPathState.HasPath` (or read `ds_list_size(player.botPathPath) > 0`) | bool |
| `botPathOccupied(player)` | `BotPathState.Occupied` | bool |
| `botFollowerInit(player)` / `botFollowerFree(player)` | `new PathFollower` (per bot) | - |
| `botFollowerSetMap(player)` | the path half of `ScriptedBot.SetMap`: occupancy off, `FreePath`, `HasGoal = false`, blacklist cleared, lane cleared to -1 | - |
| `botFollowerSetGoal(player, x, y)` | `PathFollower.SetGoal` (false also when `!global.botNavReady`, as `ScriptedBot.SetGoal`) | bool |
| `botFollowerStep(player, char, q6)` | `PathFollower.Step`; the weapon is `char.currentWeapon` | nav keys (`BOT_KEY_LEFT/RIGHT/JUMP/DOWN`) |
| `botFollowerApplyLaunch(player, fireKeys, aim)` | `PathFollower.ApplyLaunch` | keys in `global.botRet`, aim in `global.botRetAim` |
| `botFollowerPlan(player, x, y, q6)` | `PathFollower.Plan` | bool |
| `botFollowerTryResolveHop(player, from, to)` | `PathFollower.TryResolveHop` | edge row or -1 |
| `botRocketCapable(char)` | `RocketModel.Capable` | bool |
| `botRocketReady(char)` | `RocketModel.Ready` | bool |
| `botRocketReach(char, needVx, flightTicks, v0)` | `RocketModel.Reach` | px |
| `botJumpReach(char, needVx, flightTicks, v0)` | `JumpModel.Reach` | px |
| `botJumpRunupColumn(node, takeoffColumn, jumpDirection, maxCells, q6)` | `JumpModel.RunupColumn` | anchor column |
| `botStickyReady(char)` / `botStickyReach(...)` / `botStickyApex()` | `StickyModel.Ready` / `.Reach` / `.Apex` (`.Launch` is the constant `BOT_STICKY_LAUNCH`) | |
| `botArcClear(char, aimDegrees, speed, gravity, targetX, targetY)` | `BotArc.Clear` (combat calls it) | bool |

Internal (one per C# private method, not for other modules):
`botFollowerOffRoute`, `botFollowerWalkToGoal`, `botFollowerFollowEdge`
(SteerFall and Press inlined), `botFollowerSteerJump` (Approach inlined),
`botFollowerGate`, `botFollowerLaunch`, `botFollowerFloorUnder`,
`botFollowerTryFindEdge`.

## How the brain drives it (ScriptedBot.Poll / SetMap)

- Join: `botPathInit(player); botFollowerInit(player);` then set
  `player.botFollowerLane` if lanes are in use. `player.botPathReplanStagger`
  defaults to the Player's instance id (the reference's choice); overwrite it if
  wanted, but note a stagger below 15 (mod 45) makes `BOT_TAKEOFF_PATIENCE`
  unreachable.
- Leave: `botOccupancyRemove(player); botFollowerFree(player); botPathFree(player);`
- Dead (`player.object == -1`): `botOccupancyRemove(player); botPathFreePath(player);`
  and do not call Step.
- Alive: build the live query (`CanRocketJump` = `botRocketCapable(char)`), then
  `navKeys = botFollowerStep(player, char, q6);`, run combat, then
  `fireKeys = botFollowerApplyLaunch(player, fireKeys, aim); aim = global.botRetAim;`.
  The evasion behaviours read `player.botPathFlyingEdge` and may zero
  `player.botPathStuckTicks`.
- Graph reloaded (`global.botNavGeneration` changed) or map change:
  `botFollowerSetMap(player)` before anything else touches the route.

## Per-bot fields (on the Player)

`BotPathState`, every field as `botPath<Field>`:

| field | meaning |
|---|---|
| `botPathPath` | ds_list of node indices; empty = no route |
| `botPathOccupiedTeam` | team the route is counted against, `TEAM_SPECTATOR` = nowhere (nav writes it) |
| `botPathPathAt` | how far along the route |
| `botPathHasGoal`, `botPathGoalX`, `botPathGoalY` | the goal (snapped stand position) |
| `botPathPathStale` | route is to a goal that has since been replaced |
| `botPathArrived`, `botPathArrivedAt` | arrival, and its tick (-1) |
| `botPathReplanAt`, `botPathReplanStagger`, `botPathPlanFailUntil` | re-plan timer |
| `botPathEdgeFrom`, `botPathEdgeTo` | edge in progress, or -1 |
| `botPathStuckTicks`, `botPathOffPathTicks` | detectors |
| `botPathLastX`, `botPathLastY`, `botPathLastReplanX`, `botPathLastReplanY`, `botPathReplanNear` | moved test, anti-thrash |
| `botPathFailFrom`, `botPathFailTo`, `botPathFailCount` | off-route blame |
| `botPathFlyingEdge` | mid-way through a validated arc this tick |
| `botPathJumpHeld`, `botPathAirTicks`, `botPathTakeoffTicks`, `botPathRejumped` | per-arc state |
| `botPathRunupsStarted`, `botPathRunupsEdgeFrom`, `botPathRunupsEdgeTo`, `botPathRunupAt` | run-up |
| `botPathBlacklist` (ds_map key -> expiry), `botPathBlacklistOrder` (ds_queue of keys) | per-bot edge bans |
| `botPathRocketAim`, `botPathRocketFire`, `botPathMineFire`, `botPathMineDetonate`, `botPathStickySetup` | the launch hand-off (`StickySetup` -1 = none) |
| `botPathPlanQueryTeam`, `...HasIntel`, `...SetupGatesClosed`, `...CanDoubleJump`, `...CanRocketJump`, `...CanStickyJump` | `PlanQuery`, the traveller the route was planned for |
| diagnostics | `botPathReplans`, `GoalsSet`, `StuckFires`, `Reposts`, `OffRouteFires`, `BlacklistFires`, `RocketJumps`, `StickyJumps`, `DoubleJumps`, `UnsupportedEdgeTicks`, `RocketDuds`, `Launches`, `LaunchesUnderspeed`, `GateColdWeapon`, `GateTooFast`, `GateBackwards`, `GateShort`, `EdgeUnroutableFires` (all `botPath`-prefixed) |

`PathFollower`: `botFollowerScratch` (ds_list, the search's output before it
is installed) and `botFollowerLane` (the lane as `navSearchFind` takes it, or
-1).

Scratch globals: `global.botFollowerSteer<Field>` is the C# `Steering` struct
for the length of one `botFollowerFollowEdge` call (`TargetColumn`, `Braking`,
`WantJump`, `Tracking`, `TrackX`, `Abandon`, `TrackGate`, `TrackNeedVx`,
`TrackAlong`, `TrackDir`, `RocketFire`, `MineFire`, `MineDetonate`).

## Game variables read (verified in the game source)

`Character`: `x`, `y`, `hspeed`, `onground`, `moveStatus`, `hp`, `runPower`,
`basemaxspeed`, `baseFriction`, `baseControl`, `intel`, `currentWeapon`,
`player` (`Player.humiliated`). Weapon: `object_index`
(`Rocketlauncher`/`Minegun`), `readyToShoot`, `ammoCount`. Terrain:
`collision_point(.., CustomMapO, true, true)`, `collision_line_bulletblocking`.
