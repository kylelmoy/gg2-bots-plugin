// navGraphEdgeRoutable(edge, team, hasIntel, setupGatesClosed, canDoubleJump,
// canRocketJump, canStickyJump): NavGraph.EdgeRoutable - gate and class arcs.
// navSearchFind and navSearchLiveChainCost inline this; keep all three
// identical.
var e, gate, kind, ok;
e = argument0;
gate = ds_grid_get(global.botNavEdges, NAV_EDGE_GATE, e);
ok = navGraphGatePassable(gate, argument1, argument2, argument3);
if (!ok)
    return false;
kind = ds_grid_get(global.botNavEdges, NAV_EDGE_TYPE, e);
if (kind == NAV_EDGE_DOUBLEJUMP && !argument4)
    return false;
if (kind == NAV_EDGE_STICKYJUMP && !argument6)
    return false;
if (kind == NAV_EDGE_ROCKETJUMP && !argument5)
    return false;
return true;
