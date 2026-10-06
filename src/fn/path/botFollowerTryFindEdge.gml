// botFollowerTryFindEdge(player, fromNode, toNode) - PathFollower.TryFindEdge
// (navEdgeFind): the edge between two nodes that the search would have taken,
// if the graph still has one this traveller may use. Returns the edge's row in
// global.botNavEdges, or -1.
//
// NOT the first match. A route is a list of nodes and a pair can carry several
// parallel edges (walk+fall, fall+jump, double-jump+rocket-jump...); the search
// refuses per EDGE, so taking the first had a soldier steering a rocket-jump
// route as a double jump and a demoman waiting for a launcher it does not
// carry. A* keeps the strictly cheapest and the first wins a tie, so: lowest
// Cost, first-in-order on ties. (The occupancy multiplier is keyed on the node
// pair, so it cannot reorder parallel edges.)
//
// Resolved against the route's PlanQuery, never the live query: a launcher
// that goes cold on the tick after takeoff must not change which edge is being
// steered halfway along it. No usable edge is a re-plan, not a fallback.
var p, fromNode, toNode, start, stop, e, best, bestCost, cost, ok;
p = argument0;
fromNode = argument1;
toNode = argument2;

// NavGraph.EdgesFrom: out of range or no edges is the empty slice.
if (fromNode < 0 or fromNode >= global.botNavNodeCount)
    return -1;

start = ds_grid_get(global.botNavEdgeStart, 0, fromNode);
if (start < 0)
    return -1;
stop = start + ds_grid_get(global.botNavEdgeStart, 1, fromNode);

best = -1;
bestCost = 0;

for (e = start; e < stop; e += 1)
{
    if (ds_grid_get(global.botNavEdges, NAV_EDGE_TO, e) != toNode)
        continue;

    ok = navGraphEdgeRoutable(e, p.botPathPlanQueryTeam, p.botPathPlanQueryHasIntel,
        p.botPathPlanQuerySetupGatesClosed, p.botPathPlanQueryCanDoubleJump,
        p.botPathPlanQueryCanRocketJump, p.botPathPlanQueryCanStickyJump);
    if (!ok)
        continue;

    // Strictly cheaper, so an equal cost leaves the earlier one standing.
    cost = ds_grid_get(global.botNavEdges, NAV_EDGE_COST, e);
    if (best >= 0 and cost >= bestCost)
        continue;

    best = e;
    bestCost = cost;
}

return best;
