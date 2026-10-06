// navDistBetween(table, from, goal): NavDistances.Between - the cheapest cost
// from `from` to `goal` on that table's graph, or NAV_INF when there is no
// route at all (or either node, or the table, is out of range). Test for "no
// route" with `>= NAV_INF`.
//
// The table is a handle from navDistFor. The file stores floor(cost * 16), so
// this is up to 1/16 below the C#'s float: still never above the true
// remaining cost, which is what a heuristic needs (docs/NAVFILES.md).
var t, from, goal, n, raw;
t = argument0;
from = argument1;
goal = argument2;
n = global.navDistNodes;
if (!global.navDistReady || t < 0 || t >= global.navDistTableCount || from < 0 || goal < 0 || from >= n || goal >= n)
    return NAV_INF;
buffer_set_readpos(global.navDistBuffer, global.navDistCostAt[t] + 4 * (goal * n + from));
raw = read_uint(global.navDistBuffer);
if (raw >= NAV_DIST_UNREACHABLE || raw < 0)
    return NAV_INF;
return raw / NAV_DIST_SCALE;
