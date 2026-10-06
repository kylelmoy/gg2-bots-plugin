// navSearchLiveChainCost(node): NavSearch.LiveChainCost - the distance table's
// next-hop chain from node to the current search's goal, priced at what THIS
// asker would pay for it now, or NAV_INF if a hop is gated, blacklisted, out
// of class or missing. Only valid inside navSearchFind, whose asker, modifiers
// and table it reads from global.navSearchQ*.
//
// Memoised per search in the scratch's NAV_SEARCH_LIVE column (-1 = not
// walked), so a chain walked from one node is not walked again from any node
// on it. Iterative, with the walk's stack in the NAV_SEARCH_WALK column.
//
// Each hop is priced as NavSearch.LiveEdgeCost does (inlined here): the
// cheapest ROUTABLE edge between the pair under the lane's or the graph's
// cost, refused whole if the pair is blacklisted and multiplied whole by its
// crowd. At or above the table's distance by construction. The routable test
// is navGraphEdgeRoutable's rule, inlined - keep the copies identical.
//
// "Infinity" saturates at NAV_INF so that one broken chain never looks
// cheaper than another.
var node, goal, sc, n, edges, buf, nextRow, walkLen, at, hop, tail, i, from, to, memo;
var blocked, occ, lane, lanes, crowd, key, best, e, eEnd, gate, ok, kind, cost;
node = argument0;
goal = global.navSearchQGoal;
if (node == goal)
    return 0;
sc = global.navSearchScratch;
memo = ds_grid_get(sc, NAV_SEARCH_LIVE, node);
if (memo >= 0)
    return memo;

n = global.botNavNodeCount;
edges = global.botNavEdges;
buf = global.navDistBuffer;
nextRow = global.navSearchQNextRow;

// Climb to the goal, to a node already priced, or off the end of the chain.
walkLen = 0;
at = node;
while (true)
{
    if (at == goal)
        break;
    if (at < 0)
        break;
    if (ds_grid_get(sc, NAV_SEARCH_LIVE, at) >= 0)
        break;
    if (walkLen >= n)
        break;
    ds_grid_set(sc, NAV_SEARCH_WALK, walkLen, at);
    walkLen += 1;
    buffer_set_readpos(buf, nextRow + 2 * at);
    hop = read_ushort(buf);
    if (hop >= n)
        at = -1;
    else
        at = hop;
}

// What the rest costs from where the walk stopped: nothing at the goal, the
// memo at a node already walked, infinity off the end of a broken chain (no
// hop, or a cycle).
if (at == goal)
    tail = 0;
else if (at >= 0)
{
    tail = ds_grid_get(sc, NAV_SEARCH_LIVE, at);
    if (tail < 0)
        tail = NAV_INF;
}
else
    tail = NAV_INF;

blocked = global.navSearchQBlocked;
occ = global.navSearchQOccupancy;
lane = global.navSearchQLane;
lanes = global.botLanesCost;

for (i = walkLen - 1; i >= 0; i -= 1)
{
    from = ds_grid_get(sc, NAV_SEARCH_WALK, i);
    if (i + 1 < walkLen)
        to = ds_grid_get(sc, NAV_SEARCH_WALK, i + 1);
    else
        to = at;

    if (tail < NAV_INF)
    {
        // NavSearch.LiveEdgeCost(from, to).
        best = NAV_INF;
        crowd = 0;
        ok = true;
        if (blocked >= 0 || occ >= 0)
        {
            key = from * NAV_KEY_STRIDE + to;
            if (blocked >= 0)
            {
                if (ds_map_exists(blocked, key))
                    ok = false;
            }
            if (occ >= 0)
            {
                if (ds_map_exists(occ, key))
                    crowd = ds_map_find_value(occ, key);
            }
        }
        if (ok)
        {
            e = ds_grid_get(global.botNavEdgeStart, 0, from);
            eEnd = -1;
            if (e >= 0)
                eEnd = e + ds_grid_get(global.botNavEdgeStart, 1, from);
            for (e = e; e < eEnd; e += 1)
            {
                if (ds_grid_get(edges, NAV_EDGE_TO, e) != to)
                    continue;
                gate = ds_grid_get(edges, NAV_EDGE_GATE, e);
                if (gate != NAV_GATE_NONE)
                {
                    ok = false;
                    if (gate == NAV_GATE_TEAM_RED)
                        ok = global.navSearchQRedTeam;
                    else if (gate == NAV_GATE_TEAM_BLUE)
                        ok = global.navSearchQBlueTeam;
                    else if (gate == NAV_GATE_INTEL_RED)
                        ok = global.navSearchQRedIntel;
                    else if (gate == NAV_GATE_INTEL_BLUE)
                        ok = global.navSearchQBlueIntel;
                    else if (gate == NAV_GATE_SETUP)
                        ok = global.navSearchQSetup;
                    if (!ok)
                        continue;
                }
                kind = ds_grid_get(edges, NAV_EDGE_TYPE, e);
                if (kind == NAV_EDGE_DOUBLEJUMP && !global.navSearchQDoubleJump)
                    continue;
                if (kind == NAV_EDGE_STICKYJUMP && !global.navSearchQStickyJump)
                    continue;
                if (kind == NAV_EDGE_ROCKETJUMP && !global.navSearchQRocketJump)
                    continue;
                if (lane >= 0)
                    cost = ds_grid_get(lanes, lane, e);
                else
                    cost = ds_grid_get(edges, NAV_EDGE_COST, e);
                if (crowd > 0)
                    cost *= 1 + (BOT_OCCUPANCY_COST * crowd);
                if (cost < best)
                    best = cost;
            }
        }
        tail += best;
        if (tail > NAV_INF)
            tail = NAV_INF;
    }
    ds_grid_set(sc, NAV_SEARCH_LIVE, from, tail);
}

return ds_grid_get(sc, NAV_SEARCH_LIVE, node);
