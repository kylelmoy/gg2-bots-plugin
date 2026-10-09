// botLanesSweep(costLane, used, penalty, scratch, open): BotLanes.Sweep - write
// penalty into used (1 x edgeCount ds_grid) for every edge on the cheapest
// routes under lane costLane. scratch: BOT_LANES_FIELDS x nodeCount ds_grid;
// open: empty ds_priority. Dijkstra from every 7th start to every 11th goal,
// at most BOT_LANES_SWEEP_LEGS legs.
// Departure: closed flag instead of the C#'s `du > dist[u]` check; same result.
var costLane, used, penalty, sc, open, n, edges, lanes, legs, start, u, du, e, eEnd, v, nd, goal, at, guard, edge;
costLane = argument0;
used = argument1;
penalty = argument2;
sc = argument3;
open = argument4;
n = global.botNavNodeCount;
edges = global.botNavEdges;
lanes = global.botLanesCost;
legs = 0;
for (start = 0; start < n && legs < BOT_LANES_SWEEP_LEGS; start += 7)
{
    ds_grid_set_region(sc, BOT_LANES_DIST, 0, BOT_LANES_DIST, n - 1, NAV_INF);
    ds_grid_set_region(sc, BOT_LANES_FROM, 0, BOT_LANES_FROM, n - 1, -1);
    ds_grid_set_region(sc, BOT_LANES_CLOSED, 0, BOT_LANES_CLOSED, n - 1, 0);
    ds_priority_clear(open);
    ds_grid_set(sc, BOT_LANES_DIST, start, 0);
    ds_priority_add(open, start, 0);
    while (!ds_priority_empty(open))
    {
        u = ds_priority_delete_min(open);
        if (ds_grid_get(sc, BOT_LANES_CLOSED, u))
            continue;
        ds_grid_set(sc, BOT_LANES_CLOSED, u, 1);
        du = ds_grid_get(sc, BOT_LANES_DIST, u);
        e = ds_grid_get(global.botNavEdgeStart, 0, u);
        if (e < 0)
            continue;
        eEnd = e + ds_grid_get(global.botNavEdgeStart, 1, u);
        for (e = e; e < eEnd; e += 1)
        {
            v = ds_grid_get(edges, NAV_EDGE_TO, e);
            if (v < 0 || v >= n)
                continue;
            nd = du + ds_grid_get(lanes, costLane, e);
            if (nd >= ds_grid_get(sc, BOT_LANES_DIST, v))
                continue;
            ds_grid_set(sc, BOT_LANES_DIST, v, nd);
            ds_grid_set(sc, BOT_LANES_FROM, v, e);
            ds_priority_add(open, v, nd);
        }
    }

    for (goal = 0; goal < n && legs < BOT_LANES_SWEEP_LEGS; goal += 11)
    {
        if (goal == start)
            continue;
        if (ds_grid_get(sc, BOT_LANES_DIST, goal) >= NAV_INF)
            continue;
        legs += 1;
        at = goal;
        guard = 0;
        while (at != start && guard < n + 2)
        {
            guard += 1;
            edge = ds_grid_get(sc, BOT_LANES_FROM, at);
            if (edge < 0)
                break;
            ds_grid_set(used, 0, edge, penalty);
            at = ds_grid_get(edges, NAV_EDGE_FROM, edge);
        }
    }
}
