// navGraphEdgeRoutable(edge, team, hasIntel, setupGatesClosed, canDoubleJump,
// canRocketJump, canStickyJump): NavGraph.EdgeRoutable - whether this asker
// (a NavQuery, as its six arguments) may take edge (a row of
// global.botNavEdges) at all: the gate and the class arcs together.
//
// The one copy of the rule other modules call (PathFollower re-resolves the
// hop it is steering with it). navSearchFind and navSearchLiveChainCost carry
// an inlined copy for speed; the three must stay identical - a follower
// steering an edge the search refused is a bot flying an arc its route never
// costed. Refusing is the DEFAULT for every class arc.
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
