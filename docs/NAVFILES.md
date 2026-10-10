# Nav files and the generator

The plugin builds a map's nav graph and distance tables itself, in GML
(`src/fn/navgen`, a port of gg2-server's `GG2.Nav` generator and of
`gg2-navgen.exe`'s distance file; departures in `docs/departures/navgen.md`),
in the background the first time a map is played, and keeps them as files.
`gg2-navgen.exe` - gg2-server's own generator behind a small command line - is
no longer shipped; it is the reference `tools/navbench.js` checks the GML
against, and it still writes the stock maps' files for a dev game
(`tools/navdata.js`).

## Where

`Plugins/bots/nav/` beside the game. The zip ships the graph (`.txt`) of
every stock map area (1.1 MB deflated; `tools/build.js --zip` refuses to build
without all 24, which `tools/navdata.js` writes). It ships no `.dist` (32 MB
deflated): a stock map's tables, and a custom map's graph and tables, are
generated on the hosting machine the first time the map is played there, if
`[Bots] NavGenerate` is on, and kept there.

## The key

`<name>_a<area>` for a map whose `global.currentMapMD5` is empty (every
built-in map), else `<name>_<md5>_a<area>`, so two different custom maps under
one name never share a graph. `<name>` is sanitised exactly as
`NavCache.Key` does: every character outside `[A-Za-z0-9_-]` becomes `_`.

## `<key>.txt` - the graph

Byte-for-byte what gg2-server's `NavCacheWriter` writes uncompressed (and what
`nav/*.txt.gz` in gg2-server holds compressed):

```
navgraph 15
<maskWidth> <maskHeight> <nodeCount> <edgeCount>
<node grid: ds_grid_write hex, NAV_NODE_FIELDS x nodeCount>
<edge grid: ds_grid_write hex, NAV_EDGE_FIELDS x edgeCount, grouped by From>
```

Lines 3 and 4 load with `ds_grid_read` directly (GM8's own format, type tag
601). The version on line 1 is `NAV_CACHE_VERSION`; a file with any other is
refused.

## `<key>.dist` - the distance tables (optional)

What `NavDistanceSet` holds, precomputed, so the plugin never derives it (the
C# derives a missing one in ~0.4 s; GML would take minutes). Read with Faucet
buffers (`append_file_to_buffer`, `buffer_set_readpos`, `read_uint`,
`read_ushort`), little-endian, which is the game's global setting
(`set_little_endian_global(true)` in `game_init`).

```
offset  size  field
0       8     "GG2BDIST" (ASCII)
8       4     uint  format version = 1
12      4     uint  nodeCount   } must equal the graph's, or the file is ignored
16      4     uint  edgeCount   }
20      4     uint  present: the arc kinds the graph has (DoubleJump 1, RocketJump 2, StickyJump 4)
24      4     uint  tableCount
28      ...   tableCount tables, each:
              4            uint   key: a profile, already masked by `present`
              4*N*N        uint   cost, index (goal*N + from): floor(cost * 16), 4294967295 = unreachable
              2*N*N        ushort next hop, index (goal*N + from), 65535 = none
```

One table for every distinct `k & present`, `k` in 0..7. A query's profile is
`(canDoubleJump ? 1 : 0) | (canRocketJump ? 2 : 0) | (canStickyJump ? 4 : 0)`,
masked by `present`, which names its table.

**Cost is fixed point and rounded DOWN** (1/16 of a cost unit). The tables are
an A* heuristic and must never over-estimate (`NavDistances` does the same
with `MathF.BitDecrement`); flooring keeps that. The effect is a heuristic up to
1/16 low - ties can break differently from the C#, routes cannot be worse.

## Writing them

The GML writes each file to `<key>.<ext>.tmp` and renames it into place, so
the plugin - which treats a map as ready when `<key>.txt` exists - never reads
half a file. The graph is written first and installed at once; the tables
follow when they are done (`.dist`'s header names the graph's node and edge
counts, so a stale one is refused). A graph whose `.dist` is missing gets its
tables generated the next time it is loaded.

The reference generator writes the same two files, `.dist` first and `.txt`
last:

```
gg2-navgen --map <name-or-png-path> [--area <n>] --key <key> --out <dir>
gg2-navgen --all --out <dir>          every map gg2-server ships, every area
```

- `--area` defaults to 1. A name is one of gg2-server's `maps/` (embedded in
  the exe, so nothing else ships with it); anything ending in `.png` is a map
  file read for its zTXt level data. `--key` must be `[A-Za-z0-9_-]+`.
- `--all` writes `<name>_a<area>` for the 22 maps a stock game ships
  (`gg_debug` included), every area: 24 pairs, as `cp_dirtbowl` has three. `gg_debug2` (authored in gg2-server, not in the
  game) is skipped, though `--map gg_debug2` works.
- Tables are written in ascending key order. The header's `present` is
  exactly what `NavDistanceSet.PresentArcs` reports, and for a graph built
  without `--sticky` (always, here) bit 4 is never set.
- Quiet: nothing on stdout (`--verbose` prints per-graph size and time).
  Exit 0 on success; 1 on a failure (bad PNG, I/O), 2 on a usage error (an
  unknown map name, `--area` out of range, a bad key); the reason is on
  stderr either way. On failure the temporary file is deleted and neither
  final name is touched, so a previous `<key>.txt` stays as it was.
- Temporaries are `<key>.dist.<pid>.tmp` and `<key>.txt.<pid>.tmp` in
  `--out`; a crash can leave one, and nothing reads them.

### What it costs

Measured 2026-10-08 on the dev machine with `tools/navbench.js` (generation
stepped back to back, so CPU time) against the published exe, all 24 stock
map areas. Every graph is the exe's (same nodes and edge rows, floats within
1e-13); every table cost is the exe's; 0.02-0.57% of next hops differ on ties.

| | GML graph | GML tables | exe, graph + tables |
|---|---|---|---|
| `gg_debug` | 1.2 s | 0.1 s | 43 ms |
| `ctf_2dfort` (378 nodes) | 7.7 s | 11.0 s | 106 ms |
| `ctf_truefort` (687 nodes) | 16.8 s | 36.0 s | 235 ms |
| `cp_dirtbowl` area 2 (837 nodes) | 15.6 s | 19.2 s | 199 ms |
| `ctf_conflict` (762 nodes, the slowest graph) | 17.9 s | 36.8 s | 226 ms |
| `ctf_waterway` (the slowest tables) | 17.1 s | 48.2 s | 255 ms |
| all 24 | 246 s | 398 s | 3.4 s |

So the GML is roughly 70x the exe on the graph and 150x on the tables. 90% of
the graph is the three jump fans (the clearance walk and the run-up
integration, a few million interpreted steps). In a live game generation runs
a slice a tick (`NAV_GEN_BUDGET_MS`, in practice one ~16 ms clock step) and
took ~45% of the server's wall time without dropping it below 30 fps; the
longest single slice was 47 ms. On ctf_2dfort bots were walking ~30 s after
the map loaded and had their tables at ~60 s.

The reference generator alone:

Measured 2026-10-06, the published exe on the dev machine, warm disk:

| | |
|---|---|
| `--map gg_debug` | ~40-80 ms end to end |
| `--map ctf_truefort` (687 nodes) | ~230 ms; 2.0 MB `.txt`, 10.8 MB `.dist` |
| `--map cp_dirtbowl --area 2` (835 nodes) | ~190 ms; 2.5 MB `.txt`, 16.8 MB `.dist` |
| `--all` | ~0.5-0.8 s; 48 files, 183.6 MB (about 31 MB deflated, almost all `.dist`) |

The `.dist` files are the bulk: `6 * N * N` bytes per table, 2-4 tables a
map. They deflate about 6:1, which is why the zip ships graphs but no tables.

## Building the reference generator

The C# is in a gg2-server worktree, `D:/Code/gg2-server-botsplugin`, branch
`bots-plugin-navgen` (not merged into gg2-server's main): project
`src/GG2.NavGen` (`gg2-navgen.exe`, referencing `GG2.Nav` and `GG2.Bots`),
test `tests/GG2.Tests/PluginNavGenTests.cs`.

```
git -C D:/Code/gg2-server worktree add D:/Code/gg2-server-botsplugin bots-plugin-navgen   # once

# self-contained, single file, trimmed, ReadyToRun, win-x64 (~16 MB)
dotnet publish D:/Code/gg2-server-botsplugin/src/GG2.NavGen -c Release -r win-x64 -o D:/Code/gg2-server-botsplugin/src/GG2.NavGen/bin/publish

# copy it to build/data/navgen/, generate build/data/nav/ and copy its graphs to data/nav/
# (--publish does the step above first)
node tools/navdata.js [--publish] [--server <worktree>] [--exe <path>]

node tools/build.js          # installs data/ and build/data/ into a dev game
```

The stock maps' graphs in `data/nav/` are committed: they are what the zip
ships, and the release workflow builds from them. The exe and the distance
tables are not; `build/` is gitignored.
