// navSearchReconstructIncumbent(start, node, goal, route):
// NavSearch.ReconstructIncumbent - the incumbent route: the search's own route
// from start to node, then the distance table's next-hop chain from node to
// goal. Only valid inside navSearchFind (it reads that search's table).
//
// The chain priced finite when it became the incumbent, so every hop had a
// routable, unblocked edge then, and nothing in a search changes that. A chain
// that does not reach the goal is reported as no route at all, and route is
// cleared.
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
