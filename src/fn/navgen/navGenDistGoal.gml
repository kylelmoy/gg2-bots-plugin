// navGenDistGoal(): one goal of the current table - NavDistances.Derive's
// Dijkstra over the reverse adjacency from global.navGenDistAt, then that
// goal's row of costs and next hops appended to the table's buffers in `from`
// order. Advances the goal (and the table, and the stage) when done.
//
// Departures: a node's first pop is detected with a closed flag rather than
// `du > dist[u]` (pushes are only on a strict decrease, so the same entries are
// skipped), and ties pop in ds_priority's order, not .NET's, so between equal
// routes the hop may differ. Costs are the C#'s float32 rounded one step down
// (MathF.BitDecrement) and floored to 1/16, as PluginDistFile.Encode stores them.
var n, goal, st, pq, rev, u, du, p, last, v, via, cost, r, q, d16, e2, ulp, mant, f, buf, hb;
n = global.navGenDistNodes;
goal = global.navGenDistAt;
pq = global.navGenDistOpen;
rev = global.navGenDistScratch;
global.navGenDistStampN += 1;
st = global.navGenDistStampN;
ds_priority_clear(pq);
global.navGenDistD[goal] = 0;
global.navGenDistH[goal] = -1;
global.navGenDistSeen[goal] = st;
ds_priority_add(pq, goal, 0);
while (ds_priority_size(pq) > 0)
{
    u = ds_priority_delete_min(pq);
    if (global.navGenDistClosed[u] == st)
        continue;
    global.navGenDistClosed[u] = st;
    du = global.navGenDistD[u];
    last = global.navGenDistRevStart[u + 1];
    for (p = global.navGenDistRevStart[u]; p < last; p += 1)
    {
        v = ds_grid_get(rev, 0, p);
        via = du + ds_grid_get(rev, 1, p);
        if (global.navGenDistSeen[v] == st)
            if (via >= global.navGenDistD[v])
                continue;
        global.navGenDistSeen[v] = st;
        global.navGenDistD[v] = via;
        global.navGenDistH[v] = u;
        ds_priority_add(pq, v, via);
    }
}

buf = global.navGenDistCost;
hb = global.navGenDistHops;
for (v = 0; v < n; v += 1)
{
    if (global.navGenDistSeen[v] != st)
    {
        write_uint(buf, NAV_DIST_UNREACHABLE);
        write_ushort(hb, NAV_DIST_NO_HOP);
        continue;
    }
    cost = global.navGenDistD[v];
    if (cost <= 0)
        q = 0;
    else
    {
        // floor(BitDecrement((float)cost) * 16). The float32 sits within 2^-21
        // of cost and strictly below it, so away from an integer boundary of
        // cost * 16 that is plain floor; exactly on one it is one less.
        d16 = cost * NAV_DIST_SCALE;
        q = floor(d16);
        r = d16 - q;
        if (r == 0)
            q -= 1;
        else if (r <= d16 * 0.000000476837158203125)
        {
            // Near a boundary: round to float32 for real (ties to even), step
            // one float down (half a step below a power of two), then floor.
            e2 = floor(log2(cost));
            if (power(2, e2) > cost)
                e2 -= 1;
            if (power(2, e2 + 1) <= cost)
                e2 += 1;
            ulp = power(2, e2 - 23);
            mant = round(cost / ulp);
            if (mant == 8388608 || mant == 16777216)
                f = mant * ulp - ulp / 2;
            else
                f = mant * ulp - ulp;
            q = floor(f * NAV_DIST_SCALE);
        }
        if (q < 0)
            q = 0;
        if (q >= NAV_DIST_UNREACHABLE)
            q = NAV_DIST_UNREACHABLE - 1;
    }
    write_uint(buf, q);
    if (global.navGenDistH[v] < 0)
        write_ushort(hb, NAV_DIST_NO_HOP);
    else
        write_ushort(hb, global.navGenDistH[v]);
}

global.navGenDistAt = goal + 1;
if (global.navGenDistAt < n)
    exit;

// Table done: key, costs, hops.
buf = buffer_create();
write_uint(buf, global.navGenDistKeys[global.navGenDistTable]);
write_buffer(buf, global.navGenDistCost);
write_buffer(buf, global.navGenDistHops);
ds_list_add(global.navGenDistTables, buf);
global.navGenDistTable += 1;
if (global.navGenDistTable < global.navGenDistKeyCount)
    navGenDistTableStart();
else
    global.navGenStage = NAV_GEN_STAGE_DIST_WRITE;
