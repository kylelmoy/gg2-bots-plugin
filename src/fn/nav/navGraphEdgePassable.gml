// navGraphEdgePassable(edge, team, hasIntel, setupGatesClosed):
// NavGraph.EdgePassable - whether the edge's gate lets this traveller through.
var gate;
gate = ds_grid_get(global.botNavEdges, NAV_EDGE_GATE, argument0);
return navGraphGatePassable(gate, argument1, argument2, argument3);
