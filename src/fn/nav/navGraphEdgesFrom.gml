// navGraphEdgesFrom(node): NavGraph.EdgesFrom - node's outgoing edges as a
// contiguous range of global.botNavEdges rows.
// Returns the first row (-1 when there are none) in global.botRet, and how
// many in global.botRetCount (0 when there are none). An out-of-range node
// has none.
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
