// navDistNextHop(table, from, goal): NavDistances.NextHop - the node after
// `from` on the cheapest route to `goal` on that table's graph, or -1
// (NavDistances.None) if there is no route, `from` is the goal, or anything is
// out of range. Following it reaches the goal in at most nodeCount hops: the
// hops are the parent pointers of one shortest-path tree.
var t, from, goal, n, hop;
t = argument0;
from = argument1;
goal = argument2;
n = global.navDistNodes;
if (!global.navDistReady || t < 0 || t >= global.navDistTableCount || from < 0 || goal < 0 || from >= n || goal >= n)
    return -1;
buffer_set_readpos(global.navDistBuffer, global.navDistNextAt[t] + 2 * (goal * n + from));
hop = read_ushort(global.navDistBuffer);
if (hop >= n)
    return -1;
return hop;
