// navGraphEdgeKey(fromNode, toNode): NavGraph.EdgeKey (navEdgeKey.gml) - one
// number naming a directed edge by its endpoints: from * NAV_KEY_STRIDE + to.
// Keyed on endpoints, not on the edge's row, so a blacklist or an occupancy
// count names "the hop between these two nodes" whichever parallel edge it
// was. Exact in a GM8 real (a double) for any graph navGraphTryLoad accepts.
return (argument0 * NAV_KEY_STRIDE) + argument1;
