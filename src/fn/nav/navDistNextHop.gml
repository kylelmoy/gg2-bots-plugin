// navDistNextHop(table, from, goal): NavDistances.NextHop - next node on the
// cheapest route; -1 (None) if no route, from == goal, or out of range.
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
