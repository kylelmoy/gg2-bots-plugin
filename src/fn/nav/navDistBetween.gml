// navDistBetween(table, from, goal): NavDistances.Between - cheapest cost from
// `from` to `goal`; NAV_INF (test `>= NAV_INF`) if no route or out of range.
// table from navDistFor. Stored as floor(cost * 16): up to 1/16 below the C#,
// still admissible.
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
