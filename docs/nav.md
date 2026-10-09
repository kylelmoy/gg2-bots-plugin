# The nav module's API

`src/fn/nav/`: gg2-server's `NavGraph`, `NavCache` (loading), `NavSearch`,
`NavDistances`/`NavDistanceSet`, `BotOccupancy` and `BotLanes`, plus the
map-change half of `BotPopulationService`. Names follow PORTING.md. A NavQuery
is always the six arguments `team, hasIntel, setupGatesClosed, canDoubleJump,
canRocketJump, canStickyJump`. Constants are in `src/constants/nav.txt` and
`generated.txt`. Where the GML differs from the C#: `docs/departures/nav.md`.

## Shared state (read directly)

Everything in PORTING.md's "The nav graph in memory" table, plus:

| global | what |
|---|---|
| `global.botNavGeneration` | bumped whenever the graph bots hold node/edge indices into is dropped or replaced: every map load (a reload of the same map included) and every successful load. **A bot whose remembered value differs must drop its route, blacklist, goal and lane**, as `ScriptedBot.SetMap` does. |
| `global.botNavMap`, `global.botNavArea` | the map and area of the room being played; the graph, when `global.botNavReady`, is for them |
| `global.botNavKey` | that room's file key (`navGraphKey`) |
| `global.navDistReady` | distance tables are loaded for the graph |
| `global.navSearchPops` | entries the last `navSearchFind` popped (diagnostic) |
| `global.botOccupancyRed`, `global.botOccupancyBlue` | ds_maps edgeKey -> count; prefer `botOccupancyCounts(team)` |
| `global.botLanesCost`, `global.botLanesCount` | ds_grid lanes x edges (`ds_grid_get(global.botLanesCost, lane, edge)`), or -1 / 0 |

Every edge row is `ds_grid_get(global.botNavEdges, NAV_EDGE_<FIELD>, e)`; a
node's edges are rows `ds_grid_get(global.botNavEdgeStart, 0, n)` (-1 if none)
onward, `ds_grid_get(global.botNavEdgeStart, 1, n)` of them.

## Lifecycle (brain calls these)

| function | |
|---|---|
| `botNavInit()` | server start, after `botConfigLoad`. No graph yet. |
| `botNavFree()` | server stop. Safe twice. |
| `botNavMapCheck()` | every 30 Hz tick. Notices a new room (a new `CustomMapO` instance), frees the graph, resets occupancy (and every bot's `botPathOccupiedTeam`) and lanes, bumps the generation, loads `<key>.txt`/`.dist` from `global.botDir + "nav\"`, or generates them (`navGen*`, below; once per key per session), a slice a tick. |

`botNavLoad()` is internal to the map check.

## NavGraph (`navGraph*`)

| function | returns |
|---|---|
| `navGraphNodeFromWorld(worldX, worldY)` | the node a character standing there is on, or -1 (also -1 with no graph) |
| `navGraphSnapObjective(worldX, worldY)` | NavSnap: Node in `global.botRet` (-1 on a miss), `global.botRetDrop`, `global.botRetGoalX`, `global.botRetGoalY` |
| `navGraphAnchorColumn(worldX)` | anchor column |
| `navGraphColumnWorldX(column)` | stand x of a column |
| `navGraphFloorY(node)`, `navGraphStandY(node)` | surface y, chest y |
| `navGraphWorldSpan(node)` | Left (`global.botRet`, `global.botRetLeft`), `global.botRetRight` |
| `navGraphEdgeStart(node)` | first edge row, or -1 |
| `navGraphEdgesFrom(node)` | first edge row in `global.botRet` (-1 if none), count in `global.botRetCount` |
| `navGraphGatePassable(gate, team, hasIntel, setupGatesClosed)` | bool |
| `navGraphEdgePassable(edge, team, hasIntel, setupGatesClosed)` | bool (gate only) |
| `navGraphEdgeRoutable(edge, <NavQuery x6>)` | bool: gate and class arcs - the one rule the follower must share with the search |
| `navGraphEdgeKey(from, to)` | `from * NAV_KEY_STRIDE + to` |
| `navGraphCanAffordRocketJump(hp)`, `navGraphCanAffordStickyJump(hp)` | NavQuery's hp tests |
| `navGraphKey(map, area, md5)` | the file key (`NavCache.Key`, with the md5 overload) |
| `navGraphTryLoad(path)`, `navGraphFree()` | used by the map check |

## Distances (`navDist*`)

| function | returns |
|---|---|
| `navDistFor(<NavQuery x6>)` | a table handle for this asker, or -1 (no tables: straight-line heuristic). Valid until the generation changes. |
| `navDistBetween(table, from, goal)` | cheapest cost, or `NAV_INF` (test `>= NAV_INF`) |
| `navDistNextHop(table, from, goal)` | next node on the cheapest route, or -1 |
| `navDistLoad(path)`, `navDistFree()` | used by the map check |

## Search (`navSearch*`)

`navSearchFind(start, goal, <NavQuery x6>, route, blocked, occupancy, lane, table, plan)`
- `route`: the caller's ds_list; cleared, then start..goal inclusive; empty on failure.
- `blocked`: ds_map whose keys are `navGraphEdgeKey`s to refuse, or -1.
- `occupancy`: `botOccupancyCounts(team)` when occupancy is on, else -1.
- `lane`: `botLanesCosts(botLane)`, or -1.
- `table`: `navDistFor(<NavQuery>)` (pass -1 when `global.botNavDistancesOn` is off; `botNavMapCheck` already loads none then).
- `plan`: `NAV_PLAN_DECIDE_BY_CROWD` (the C# default).
- Returns found (`global.botRet`). So `Find(start, goal, query, scratch, state.Blacklist, occupancy?.Counts(query.Team), Lane.Span, Distances?.For(query))` becomes
  `ok = navSearchFind(start, goal, team, intel, setup, dj, rj, sj, scratch, blacklistMap, occ, lane, table, NAV_PLAN_DECIDE_BY_CROWD);`

One search runs at a time: the scratch is shared. `navSearchLiveChainCost`,
`navSearchReconstruct` and `navSearchReconstructIncumbent` are internal to it.

## Occupancy (`botOccupancy*`)

Per bot it uses the path module's `player.botPathPath` (ds_list of nodes) and
`player.botPathOccupiedTeam` (TEAM_RED/TEAM_BLUE when counted, TEAM_SPECTATOR
when not - `botPathInit` must set TEAM_SPECTATOR). Occupancy owns that field.

| function | |
|---|---|
| `botOccupancyAdd(player, team)` | count the installed route under team; idempotent |
| `botOccupancyRemove(player)` | uncount it, against the team it was counted under; call before clearing the route |
| `botOccupancyCounts(team)` | the team's ds_map for `navSearchFind`, or -1 |
| `botOccupancyEdgeCount(team)` | edges with anything on them |
| `botOccupancyReset()` | both maps and every bot's flag; the map check calls it |
| `botOccupancyMap`, `botOccupancyApply`, `botOccupancyForget` | internal |

## Lanes (`botLanes*`)

| function | |
|---|---|
| `botLanesDerive(lanes, penalty)` | derive lane fields for the current graph (`BOT_LANES_PENALTY` is the C# default). **Expensive** - one interpreted Dijkstra per swept start; nothing calls it automatically, as gg2-server's live server never derives lanes. |
| `botLanesCosts(lane)` | the lane's column for `navSearchFind` (wraps), or -1 with no lanes |
| `botLanesFree()` | drop them; the map check calls it |
| `botLanesSweep` | internal |

## Generator (`navGen*`, `src/fn/navgen/`)

GG2.Nav's `NavGenerator` and the plugin's distance file, in GML
(docs/departures/navgen.md). Driven by `botNavMapCheck`; nothing else calls it.

| function | |
|---|---|
| `navGenInit()`, `navGenFree()` | with `botNavInit`/`botNavFree`; `navGenFree` also aborts a run (the map check calls it on every new room) |
| `navGenStart(key, distOnly)` | begin `<key>.txt` from the live room (then its tables), or only the tables for the installed graph. False if there is no walkmask |
| `navGenStep(budgetMs)` | work until the budget is spent. `global.navGenStage` is `NAV_GEN_STAGE_GRAPH_DONE` when `<key>.txt` is written (install it, then `navGenDistSetup()` or `navGenFree()`), `NAV_GEN_STAGE_DONE` when finished (`global.navGenDistOk`: `<key>.dist` written) |
| `navGenDistSetup()` | start the tables for the installed graph |

Timing: `global.navGenMs` (time stepped), `global.navGenStageAt[stage]`
(`current_time` each stage began). `tools/navbench.js` reads both.
