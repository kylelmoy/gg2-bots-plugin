// navDistLoad(path): NavDistanceSet.LoadOrDerive's load arm - read <key>.dist
// for the installed graph into one buffer. False (nothing held) on mismatch.
// Departure: never derives a missing/stale file.
// Sets navDistBuffer/Nodes/Present/TableCount, navDistCostAt[t]/NextAt[t]
// (byte offsets), navDistByProfile[k] (k 0..7). Tables are [goal][from], LE.
var path, buf, n, edgeCount, present, count, t, at, key, k, masked, ok, cells, magic;
path = argument0;
navDistFree();
if (!global.botNavReady)
    return false;
if (!file_exists(path))
    return false;
n = global.botNavNodeCount;
// NextHop is a ushort; NAV_DIST_NO_HOP is the sentinel.
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

// NavDistanceSet.FromTables: map each profile (masked by `present`) to a table;
// a profile with no table refuses the file.
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
