// botJumpRunupColumn(node, takeoffColumn, jumpDirection, maxCells, team,
//                    hasIntel, setupGatesClosed, canDoubleJump, canRocketJump,
//                    canStickyJump)
// JumpModel.RunupColumn: column to back up to before an arc, following
// passable WALK edges in the graph up to maxCells. Returns takeoffColumn if
// there is nowhere to go. Only the gate half of the query is read.
var node, takeoff, dir, maxCells, qTeam, qIntel, qSetup;
var nodes, edges, want, current, frontier, hop, best, bestSpan, start, stop, e, ok;
var toNode, t0, t1;
node = argument0;
takeoff = argument1;
dir = argument2;
maxCells = argument3;
qTeam = argument4;
qIntel = argument5;
qSetup = argument6;

if (node < 0 or node >= global.botNavNodeCount or dir == 0)
    return takeoff;

nodes = global.botNavNodes;
edges = global.botNavEdges;

want = takeoff - dir * maxCells;
current = node;

// Frontier: the floor's far end away from the jump.
if (dir > 0)
    frontier = ds_grid_get(nodes, NAV_NODE_X0, current);
else
    frontier = ds_grid_get(nodes, NAV_NODE_X1, current);

for (hop = 0; hop < BOT_RUNUP_HOPS; hop += 1)
{
    if (dir > 0)
    {
        if (frontier <= want)
            break;
    }
    else
    {
        if (frontier >= want)
            break;
    }

    best = -1;
    bestSpan = 0;

    start = ds_grid_get(global.botNavEdgeStart, 0, current);
    stop = start;
    if (start >= 0)
        stop = start + ds_grid_get(global.botNavEdgeStart, 1, current);

    for (e = start; e < stop; e += 1)
    {
        if (ds_grid_get(edges, NAV_EDGE_TYPE, e) != NAV_EDGE_WALK)
            continue;

        ok = navGraphEdgePassable(e, qTeam, qIntel, qSetup);
        if (!ok)
            continue;

        toNode = ds_grid_get(edges, NAV_EDGE_TO, e);
        t0 = ds_grid_get(nodes, NAV_NODE_X0, toNode);
        t1 = ds_grid_get(nodes, NAV_NODE_X1, toNode);

        if (dir > 0)
        {
            // Adjacent on the left, and not overlapping forward.
            if (t1 < frontier - 1 or t1 >= frontier)
                continue;

            if (best < 0 or t0 < bestSpan)
            {
                best = toNode;
                bestSpan = t0;
            }
        }
        else
        {
            if (t0 > frontier + 1 or t0 <= frontier)
                continue;

            if (best < 0 or t1 > bestSpan)
            {
                best = toNode;
                bestSpan = t1;
            }
        }
    }

    if (best < 0)
        break;

    current = best;
    frontier = bestSpan;
}

if (dir > 0)
    return max(want, frontier);
return min(want, frontier);
