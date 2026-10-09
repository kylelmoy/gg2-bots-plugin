// botFollowerTryFindEdge(player, fromNode, toNode) - PathFollower.TryFindEdge:
// the cheapest edge (first on ties) between the nodes routable under the
// route's PlanQuery, as the search chose. Returns its row in
// global.botNavEdges, or -1.
var p, fromNode, toNode, start, stop, e, best, bestCost, cost, ok;
p = argument0;
fromNode = argument1;
toNode = argument2;

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

    cost = ds_grid_get(global.botNavEdges, NAV_EDGE_COST, e);
    if (best >= 0 and cost >= bestCost)
        continue;

    best = e;
    bestCost = cost;
}

return best;
