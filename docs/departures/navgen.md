# navgen: departures from the C#

`src/fn/navgen/` is gg2-server's nav generator - `GG2.Nav` (`NavGenerator`,
`NavGraphBuilder`, `NavArcModel` and its three models, `NavCharacter`,
`NavInstances`, `NavGrids`, `NavCacheWriter`) and the plugin's distance file
(`PluginDistFile` over `NavDistances.Derive`) - run inside the game, in slices,
instead of as `gg2-navgen.exe`. `tools/navbench.js` checks it against the exe
map by map; `tools/navcompare.js` is the comparison.

What it produces: the same nodes and the same edge rows as the exe on every
stock map and area, float fields within 1e-13 (x87 against IEEE doubles, below);
the same distance costs, byte for byte; next hops that differ only where two
routes cost the same.

- **It reads the live room, not the map's PNG.** The walkmask is the game's
  own collision sprite (`global.CustomMapCollisionSprite`) read a cell at a time
  through a scale-1 dummy instance, which is what the reference's
  `navBuildStart` did; the entities are the room's instances, already narrowed
  to the area by `basicRoomSetup` (the C#'s `LevelMap.ForArea`). Each object is
  matched exactly by `object_index`, as the C# matches an entity type, and its
  box is the C#'s (collider sprite size times the instance's scale, from its
  rounded position), not its live bbox. MoveBox push is the instance's
  `pushPower`, which `MoveBox`'s User Event 1 read from the same `speed`
  property the C# reads.

- **Sliding window counts are shifted grid additions.** `Clearance`'s two
  passes and `ExtractNodes`' support/platform/lethal windows are sums of shifted
  copies (`ds_grid_add_grid_region`), one native pass each; a cell is free
  where the summed grid is 0 (the C#'s `free == 1`). A third grid, `Air`, adds
  each cell to the one below it, so the arc code's "this row and the row above
  are free" (an airborne body is a row taller) is one read.

- **Candidates no arc can reach are skipped before the takeoff search.**
  `navGenModel` tabulates, per row difference, the longest flight any ceiling a
  takeoff can see and any re-jump allows, times `NAV_JUMP_VX`. A candidate whose
  nearest landing is further fails `Flight` on every takeoff and lead in the
  C#, so skipping it changes no edge. The C# jump fan already does this with
  `ReachWorld` (at the apex ceiling only); the double- and rocket-jump fans had
  nothing, and searched every surface in their rows. This alone took the GML
  graph on ctf_truefort from about 47 s to 20 s.

- **A flight time is computed once per takeoff column**, not once per landing
  lead: it depends on the ceiling (and the re-jump tick), never on the lead.

- **A kept candidate's arc is the one the candidate loop proved.** The C#
  re-derives it with a second `Takeoff` to keep one definition of a flyable arc;
  `Takeoff` is deterministic, so the stored arc is the same one.

- **The height curve is inlined in the clearance walk** (`navGenFlyable`),
  its constants computed once per arc; `navGenHeight` is the callable copy
  (`navGenArcGate`, `navGenFlightTime`'s twin). The two must stay identical.

- **x87 arithmetic.** GM8 evaluates expressions in 80-bit registers; .NET in
  IEEE doubles. Bucket, ticks and cost can differ in the last bits (at most
  3.2e-14 measured), so the files are equal as graphs, not as bytes. The C#'s
  `SamplesFor` snap exists precisely because the reference ran under x87; it is
  kept.

- **The sticky-jump fan is not ported.** The exe never ran it either
  (`NavGenerator.Build(sticky: false)`), and the plugin's search has no use for
  type 7 edges.

- **Distance tables are derived in GML, in the background, after the graph is
  live**, one goal's Dijkstra per slice. The exe derived them before writing
  the graph; here bots route by straight-line heuristic until the tables are
  in. A node's first pop is detected with a closed flag rather than
  `du > dist[u]` (pushes are only on a strict decrease, so the same entries are
  skipped). Ties pop in `ds_priority`'s order rather than .NET's, so where two
  routes cost the same the next hop can differ (about 0.05% of entries); costs
  are identical. The C#'s float32 costs (`MathF.BitDecrement((float)d)`) are
  emulated before the 1/16 floor, so they are identical to the byte.

- **Everything runs in slices** (`navGenStep`, `NAV_GEN_BUDGET_MS` a tick):
  a mask row, one whole-grid pass, a node row, a node-side of a fan, one goal of
  a table. The C# collapsed the reference's chunked state machine into one pass
  because it had no clients; this has.
