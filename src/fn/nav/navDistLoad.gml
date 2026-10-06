// navDistLoad(path): NavDistanceSet.LoadOrDerive's load arm, over the plugin's
// own <key>.dist (docs/NAVFILES.md) - read the tables for the INSTALLED graph.
// Returns true when they are usable; false, with global.navDistReady false and
// nothing held, otherwise.
//
// Never derived: the C# derives a missing or stale file in ~0.4 s, GML would
// take minutes. A file that does not match the graph (node or edge count, a
// missing profile table, a short file) is ignored, and searches fall back to
// the straight-line heuristic - the C#'s no-distances arm.
//
// The whole file goes into one Faucet buffer (native, fast), and Between and
// NextHop read it in place with buffer_set_readpos + read_uint/read_ushort,
// little-endian (the game's global setting). Tables are laid out [goal][from].
//
// Sets global.navDistBuffer, global.navDistNodes, global.navDistPresent,
// global.navDistTableCount, global.navDistCostAt[t] / global.navDistNextAt[t]
// (byte offsets of table t's cost and next-hop halves) and
// global.navDistByProfile[k] (the table for raw profile k, 0..7).
var path, buf, n, edgeCount, present, count, t, at, key, k, masked, ok, cells, magic;
path = argument0;
navDistFree();
if (!global.botNavReady)
    return false;
if (!file_exists(path))
    return false;
n = global.botNavNodeCount;
// NextHop is a ushort with one value kept as the sentinel.
if (n >= NAV_DIST_NO_HOP)
    return false;

buf = buffer_create();
append_file_to_buffer(buf, path);
if (buffer_size(buf) < NAV_DIST_HEADER_BYTES)
{
    buffer_destroy(buf);
    return false;
}
buffer_set_readpos(buf, 0);
magic = read_string(buf, 8);
ok = (magic == "GG2BDIST");
if (read_uint(buf) != NAV_DIST_VERSION)
    ok = false;
if (read_uint(buf) != n)
    ok = false;
edgeCount = read_uint(buf);
if (edgeCount != global.botNavEdgeCount)
    ok = false;
present = read_uint(buf);
count = read_uint(buf);
if (count < 1 || count > NAV_DIST_PROFILES)
    ok = false;
cells = n * n;
if (buffer_size(buf) != NAV_DIST_HEADER_BYTES + count * (4 + 6 * cells))
    ok = false;
if (!ok)
{
    buffer_destroy(buf);
    return false;
}

at = NAV_DIST_HEADER_BYTES;
for (t = 0; t < count; t += 1)
{
    buffer_set_readpos(buf, at);
    global.navDistKey[t] = read_uint(buf);
    global.navDistCostAt[t] = at + 4;
    global.navDistNextAt[t] = at + 4 + 4 * cells;
    at += 4 + 6 * cells;
}

// NavDistanceSet.FromTables: expand the distinct tables over all eight raw
// profile keys, masking with the `present` the writer recorded - which is
// what makes a sticky-jumper read the walker's table on a graph with no
// sticky arcs. A profile with no table refuses the file.
for (k = 0; k < NAV_DIST_PROFILES; k += 1)
{
    masked = k & present;
    global.navDistByProfile[k] = -1;
    for (t = 0; t < count; t += 1)
    {
        if (global.navDistKey[t] == masked)
        {
            global.navDistByProfile[k] = t;
            break;
        }
    }
    if (global.navDistByProfile[k] < 0)
        ok = false;
}
if (!ok)
{
    buffer_destroy(buf);
    for (k = 0; k < NAV_DIST_PROFILES; k += 1)
        global.navDistByProfile[k] = -1;
    return false;
}

global.navDistBuffer = buf;
global.navDistNodes = n;
global.navDistPresent = present;
global.navDistTableCount = count;
global.navDistReady = true;
return true;
