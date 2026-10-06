# Nav files and the generator

Building a nav graph is seconds of work in GML and a fraction of a second in
C#, so the plugin never builds one. `gg2-navgen.exe` - gg2-server's own
generator (`GG2.Nav`) behind a small command line, built in a gg2-server
worktree - writes the files, and the plugin only reads them.

## Where

`Plugins/bots/nav/` beside the game. Shipped maps' files are generated at
release time and shipped; anything else (a custom map) is generated on this
machine the first time the map is played, if `[Bots] NavGenerate` is on.

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

Both files are written to a temporary name and renamed into place, `.dist`
first and `.txt` last, so the plugin - which treats a map as ready when
`<key>.txt` exists - never reads half a file.

```
gg2-navgen --map <name-or-png-path> [--area <n>] --key <key> --out <dir>
gg2-navgen --all --out <dir>          every map gg2-server ships, every area
```
