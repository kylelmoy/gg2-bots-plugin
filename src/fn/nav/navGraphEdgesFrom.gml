// navGraphEdgesFrom(node): NavGraph.EdgesFrom - first outgoing edge row in
// global.botRet (-1 if none), count in global.botRetCount (0 if none).
var n, first;
n = argument0;
global.botRetCount = 0;
if (n < 0 || n >= global.botNavNodeCount)
    return -1;
first = ds_grid_get(global.botNavEdgeStart, 0, n);
if (first < 0)
    return -1;
global.botRetCount = ds_grid_get(global.botNavEdgeStart, 1, n);
return first;
