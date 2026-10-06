// navGraphEdgeStart(node): NavGraph.EdgeStart - where node's outgoing edges
// begin in global.botNavEdges, or -1 if it has none or is out of range.
// The i-th edge of navGraphEdgesFrom(node) is row EdgeStart(node) + i.
// Hot loops should read global.botNavEdgeStart directly instead.
var n;
n = argument0;
if (n < 0 || n >= global.botNavNodeCount)
    return -1;
return ds_grid_get(global.botNavEdgeStart, 0, n);
