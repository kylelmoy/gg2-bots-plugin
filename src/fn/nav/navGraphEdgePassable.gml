// navGraphEdgePassable(edge, team, hasIntel, setupGatesClosed):
// NavGraph.EdgePassable - whether this traveller may take edge (a row of
// global.botNavEdges) as far as gates go.
//
// The test is on the EDGE, not on the node it arrives at: the generator stamps
// an edge that passes through a gate with that gate, so this covers both. It
// also means a bot standing inside a gate it may not pass still gets edges out.
var gate;
gate = ds_grid_get(global.botNavEdges, NAV_EDGE_GATE, argument0);
return navGraphGatePassable(gate, argument1, argument2, argument3);
