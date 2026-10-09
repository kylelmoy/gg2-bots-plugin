// navSearchReconstructIncumbent(start, node, goal, route):
// NavSearch.ReconstructIncumbent - search route start..node, then the table's
// next-hop chain node..goal. Only inside navSearchFind. False (route cleared)
// if the chain doesn't reach goal.
var start, node, goal, route, ok, at, guard, n, buf, nextRow, hop;
start = argument0;
node = argument1;
goal = argument2;
route = argument3;
ok = navSearchReconstruct(start, node, route);
if (!ok)
    return false;
n = global.botNavNodeCount;
buf = global.navDistBuffer;
nextRow = global.navSearchQNextRow;
at = node;
guard = 0;
while (at != goal)
{
    buffer_set_readpos(buf, nextRow + 2 * at);
    hop = read_ushort(buf);
    if (hop >= n)
        at = -1;
    else
        at = hop;
    guard += 1;
    if (at < 0 || guard > n)
    {
        ds_list_clear(route);
        return false;
    }
    ds_list_add(route, at);
}
return true;
