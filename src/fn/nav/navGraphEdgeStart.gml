// navGraphEdgeStart(node): NavGraph.EdgeStart - first outgoing edge row in
// global.botNavEdges; -1 if none or out of range.
var n;
n = argument0;
if (n < 0 || n >= global.botNavNodeCount)
    return -1;
return ds_grid_get(global.botNavEdgeStart, 0, n);
