# nav: departures from the C#

- **Distances are loaded, never derived, and floored to 1/16.** The C#
  derives a missing table (`NavDistanceSet.LoadOrDerive`); GML would take
  minutes, so a missing or mismatched `.dist` means no tables and the
  straight-line heuristic (the C#'s no-distances arm). The file stores
  `floor(cost * 16)` (docs/NAVFILES.md), so `Between` can sit up to 1/16 below
  the C#'s float. Still admissible.

- **The incumbent tests carry a 1/16 slack (`NAV_DIST_QUANTUM`).** The C#
  accepts its incumbent when `f * (1 + 1e-6) >= bound`, and ChainOrSearch
  accepts a chain when `chain <= Between * (1 + 1e-6)`. With floored
  distances an unperturbed chain no longer passes either, and the search would
  grind on to prove it: on ctf_truefort, first-pop answers fell from 935 to 40
  of 1,365 sampled searches and pops rose 124 -> 160. Both tests here add
  `NAV_DIST_QUANTUM` to the lower bound. They fire whenever the C#'s would, and
  can accept a route at most 1/16 of a cost unit (plus the relative tolerance)
  above the optimum. No sampled route on ctf_truefort or cp_dirtbowl was dearer
  than a reference Dijkstra.

- **Ties break by GM8's `ds_priority`, not .NET's `PriorityQueue`.** Equal-f
  frontier entries (and equal-distance Dijkstra entries in `botLanesSweep`)
  can pop in a different order, so between routes of equal cost the GML may
  pick another one. Costs and reachability are unchanged.

- **The open set's values are entry numbers, not nodes.** `ds_priority` cannot
  return the priority of what it pops when a node is queued twice, and the
  incumbent test needs that f. Each push appends the node and f to
  `global.navSearchEntryNode`/`EntryF` and queues the entry number. Behaviour is
  the same.

- **`botLanesSweep` skips stale entries with a closed flag** instead of
  `du > dist[u]`. Pushes only happen on a strict decrease, so both skip exactly
  the same entries.

- **The routable rule is inlined twice** (`navSearchFind`'s expansion loop and
  `navSearchLiveChainCost`), beside the one callable copy,
  `navGraphEdgeRoutable`. The C# insists on one copy; a function call per edge
  is too slow in GM8. The three must be kept identical.

- **`Reconstruct` front-inserts** into the route (`ds_list_insert`) instead of
  appending and reversing: GM8 has no list reverse. Same output.

- **"Infinity" is `NAV_INF` (1e9) and saturates.** GM8 has no infinity. A
  chain cost that reaches it stays at it, so one broken chain never looks
  cheaper than another; anything `>= NAV_INF` means no route.
  `navDistBetween` returns `NAV_INF` for "no route".

- **A next hop at or past the node count is treated as no hop** (the C#
  trusts its own table); it would otherwise index past the scratch grid.

- **`botOccupancyReset` also clears every bot's `botPathOccupiedTeam`**, which
  in the C# is `ScriptedBot.SetMap`'s removal. The map check owns the reset, so
  it does both halves in one place.

- **The map change is noticed by the room, not by the map's name.**
  `BotPopulationService.MapChanged` is called by the server at each load. Here
  `botNavMapCheck` watches for a new `CustomMapO` instance (the room's creation
  code makes one per load), because `global.currentMapArea` advances at the
  round end, 300 ticks before the room changes, and a reload of the same map
  changes no name. The graph file is re-read on every load. The distance
  buffer is kept when the key and the graph size are unchanged, as
  `LoadDistances`' `_distancesKey` does.

- **A missing graph is generated in the background.** The C# builds it
  in-process at the map change, in one go. Here the GML port of the generator
  (`src/fn/navgen`, docs/departures/navgen.md) runs a slice a tick, at most once
  per key per session, and the bots fight without walking until `<key>.txt` is
  written and installed; its distance tables follow the same way, and a graph
  loaded from a file whose `.dist` is missing gets them generated too. There is
  no manifest/walkmask hash check (`NavManifest`); the md5 in the key covers
  custom maps.

- **The key carries the custom map's MD5** (`navGraphKey`'s third argument),
  as docs/NAVFILES.md specifies; the C# serves built-in maps only.

- **Lanes are never derived automatically.** gg2-server's live server does not
  derive them either (only its tests do). `botLanesDerive` exists for the
  integrator; it is an interpreted Dijkstra per swept start and costs a visible
  stall on large maps.
