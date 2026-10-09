// navSearchFind(start, goal, team, hasIntel, setupGatesClosed, canDoubleJump,
//               canRocketJump, canStickyJump, route, blocked, occupancy, lane,
//               table, plan)
// NavSearch.Find - cheapest route by A*, or CPD-Search when table >= 0.
//   team..canStickyJump: the NavQuery. route: ds_list, cleared then filled
//   start..goal inclusive (empty on failure). blocked: ds_map of refused edge
//   keys, or -1. occupancy: edgeKey -> count ds_map, or -1; edge cost scaled by
//   (1 + BOT_OCCUPANCY_COST * count). lane: botLanesCost column or -1. table:
//   asker's own navDistFor table, or -1 (weighted straight line). plan:
//   NAV_PLAN_DECIDE_BY_CROWD (C# default), _CHAIN_BOUNDS_SEARCH,
//   _CHAIN_OR_SEARCH.
// Returns found (global.botRet); global.navSearchPops = pops. Shared scratch:
// one search at a time. Edge test inlines navGraphEdgeRoutable; keep identical.
// Open set: ds_priority of entry numbers into navSearchEntryNode/EntryF (lazy
// deletion). Closed nodes are never reopened.
var start, goal, qTeam, hasIntel, setupClosed, canDJ, canRJ, canSJ, route, blocked, occ, lane, table, plan;
var n, nodes, edges, sc, open, eNode, eF, buf, costRow, okRedTeam, okBlueTeam, okRedIntel, okBlueIntel, okSetup;
var hasBlocked, hasOcc, hasLanes, lanes, goalX, goalY, raw, between, chain, bound, incumbent, current, f, guard, pops;
var gCur, e, eEnd, nxt, gate, ok, kind, cost, key, tentative, existing, est, exact, live, entry, pri;
start = argument0;
goal = argument1;
qTeam = argument2;
hasIntel = argument3;
setupClosed = argument4;
canDJ = argument5;
canRJ = argument6;
canSJ = argument7;
route = argument8;
blocked = argument9;
occ = argument10;
lane = argument11;
table = argument12;
plan = argument13;

ds_list_clear(route);
global.navSearchPops = 0;
if (!global.botNavReady)
    return false;
n = global.botNavNodeCount;
if (start < 0 || goal < 0 || start >= n || goal >= n)
    return false;
if (start == goal)
{
    ds_list_add(route, start);
    return true;
}
if (!global.navDistReady)
    table = -1;
if (table >= global.navDistTableCount)
    table = -1;

nodes = global.botNavNodes;
edges = global.botNavEdges;
sc = global.navSearchScratch;
open = global.navSearchOpen;
eNode = global.navSearchEntryNode;
eF = global.navSearchEntryF;
buf = global.navDistBuffer;

// g and cameFrom = -1, closed = 0.
ds_grid_set_region(sc, NAV_SEARCH_G, 0, NAV_SEARCH_FROM, n - 1, -1);
ds_grid_set_region(sc, NAV_SEARCH_CLOSED, 0, NAV_SEARCH_CLOSED, n - 1, 0);
ds_priority_clear(open);
ds_list_clear(eNode);
ds_list_clear(eF);

// Heuristic target: goal's midpoint, mask cells.
goalX = (ds_grid_get(nodes, NAV_NODE_X0, goal) + ds_grid_get(nodes, NAV_NODE_X1, goal)) / 2;
goalY = ds_grid_get(nodes, NAV_NODE_Y, goal);

// Unreachable in the table means unreachable for every asker.
costRow = 0;
between = 0;
if (table >= 0)
{
    costRow = global.navDistCostAt[table] + 4 * goal * n;
    buffer_set_readpos(buf, costRow + 4 * start);
    raw = read_uint(buf);
    if (raw >= NAV_DIST_UNREACHABLE || raw < 0)
        return false;
    between = raw / NAV_DIST_SCALE;
}

// Gate answers (navGraphGatePassable).
okRedTeam = (qTeam == TEAM_RED && !hasIntel);
okBlueTeam = (qTeam == TEAM_BLUE && !hasIntel);
okRedIntel = (qTeam == TEAM_RED || !hasIntel);
okBlueIntel = (qTeam == TEAM_BLUE || !hasIntel);
okSetup = !setupClosed;

hasBlocked = false;
if (blocked >= 0)
    hasBlocked = (ds_map_size(blocked) > 0);
hasOcc = false;
if (occ >= 0)
    hasOcc = (ds_map_size(occ) > 0);
hasLanes = false;
lanes = -1;
if (lane >= 0)
{
    if (lane < global.botLanesCount)
    {
        hasLanes = true;
        lanes = global.botLanesCost;
    }
}

// Read by navSearchLiveChainCost.
global.navSearchQGoal = goal;
global.navSearchQRedTeam = okRedTeam;
global.navSearchQBlueTeam = okBlueTeam;
global.navSearchQRedIntel = okRedIntel;
global.navSearchQBlueIntel = okBlueIntel;
global.navSearchQSetup = okSetup;
global.navSearchQDoubleJump = canDJ;
global.navSearchQRocketJump = canRJ;
global.navSearchQStickyJump = canSJ;
global.navSearchQBlocked = -1;
if (hasBlocked)
    global.navSearchQBlocked = blocked;
global.navSearchQOccupancy = -1;
if (hasOcc)
    global.navSearchQOccupancy = occ;
global.navSearchQLane = -1;
if (hasLanes)
    global.navSearchQLane = lane;
global.navSearchQTable = table;
global.navSearchQNextRow = 0;
if (table >= 0)
    global.navSearchQNextRow = global.navDistNextAt[table] + 2 * goal * n;

ds_grid_set(sc, NAV_SEARCH_G, start, 0);

// CPD-Search (Bono et al. 2019): incumbent = cheapest live-priced next-hop
// chain so far, bound = its cost. Seeded from start.
bound = NAV_INF;
incumbent = -1;
if (table >= 0)
{
    ds_grid_set_region(sc, NAV_SEARCH_LIVE, 0, NAV_SEARCH_LIVE, n - 1, -1);
    chain = navSearchLiveChainCost(start);
    if (plan == NAV_PLAN_DECIDE_BY_CROWD)
    {
        if (hasOcc)
            plan = NAV_PLAN_CHAIN_OR_SEARCH;
        else
            plan = NAV_PLAN_CHAIN_BOUNDS_SEARCH;
    }
    if (plan == NAV_PLAN_CHAIN_OR_SEARCH)
    {
        // Chain == table distance means unperturbed, hence optimal.
        // NAV_DIST_QUANTUM: stored distance is floored to 1/16.
        if (chain <= (between + NAV_DIST_QUANTUM) * (1 + NAV_SEARCH_INCUMBENT_TOLERANCE))
        {
            ok = navSearchReconstructIncumbent(start, start, goal, route);
            global.navSearchPops = 0;
            return ok;
        }
        // Perturbed: plain A* on the exact heuristic, no bound.
    }
    else
    {
        if (chain < NAV_INF)
            bound = chain;
        incumbent = start;
    }
    pri = between;
}
else
    pri = 0;
ds_list_add(eNode, start);
ds_list_add(eF, pri);
ds_priority_add(open, 0, pri);

current = -1;
guard = 0;
pops = 0;
while (!ds_priority_empty(open))
{
    guard += 1;
    if (guard > NAV_SEARCH_POP_GUARD)
        break;
    entry = ds_priority_delete_min(open);
    current = ds_list_find_value(eNode, entry);
    f = ds_list_find_value(eF, entry);
    pops += 1;

    // Goal test on pop.
    if (current == goal)
        break;

    // Incumbent can't be beaten. Before the closed check: a stale f still
    // bounds.
    if ((f + NAV_DIST_QUANTUM) * (1 + NAV_SEARCH_INCUMBENT_TOLERANCE) >= bound)
    {
        global.navSearchPops = pops;
        ok = navSearchReconstructIncumbent(start, incumbent, goal, route);
        return ok;
    }

    // Stale entry.
    if (ds_grid_get(sc, NAV_SEARCH_CLOSED, current))
        continue;
    ds_grid_set(sc, NAV_SEARCH_CLOSED, current, 1);

    e = ds_grid_get(global.botNavEdgeStart, 0, current);
    if (e < 0)
        continue;
    eEnd = e + ds_grid_get(global.botNavEdgeStart, 1, current);
    gCur = ds_grid_get(sc, NAV_SEARCH_G, current);

    for (e = e; e < eEnd; e += 1)
    {
        nxt = ds_grid_get(edges, NAV_EDGE_TO, e);
        if (nxt < 0 || nxt >= n)
            continue;
        if (ds_grid_get(sc, NAV_SEARCH_CLOSED, nxt))
            continue;

        // navGraphEdgeRoutable, inlined.
        gate = ds_grid_get(edges, NAV_EDGE_GATE, e);
        if (gate != NAV_GATE_NONE)
        {
            ok = false;
            if (gate == NAV_GATE_TEAM_RED)
                ok = okRedTeam;
            else if (gate == NAV_GATE_TEAM_BLUE)
                ok = okBlueTeam;
            else if (gate == NAV_GATE_INTEL_RED)
                ok = okRedIntel;
            else if (gate == NAV_GATE_INTEL_BLUE)
                ok = okBlueIntel;
            else if (gate == NAV_GATE_SETUP)
                ok = okSetup;
            if (!ok)
                continue;
        }
        kind = ds_grid_get(edges, NAV_EDGE_TYPE, e);
        if (kind >= NAV_EDGE_DOUBLEJUMP)
        {
            if (kind == NAV_EDGE_DOUBLEJUMP && !canDJ)
                continue;
            if (kind == NAV_EDGE_STICKYJUMP && !canSJ)
                continue;
            if (kind == NAV_EDGE_ROCKETJUMP && !canRJ)
                continue;
        }

        if (hasLanes)
            cost = ds_grid_get(lanes, lane, e);
        else
            cost = ds_grid_get(edges, NAV_EDGE_COST, e);

        if (hasBlocked || hasOcc)
        {
            key = current * NAV_KEY_STRIDE + nxt;
            if (hasBlocked)
            {
                if (ds_map_exists(blocked, key))
                    continue;
            }
            if (hasOcc)
            {
                if (ds_map_exists(occ, key))
                    cost *= 1 + (BOT_OCCUPANCY_COST * ds_map_find_value(occ, key));
            }
        }

        tentative = gCur + cost;
        existing = ds_grid_get(sc, NAV_SEARCH_G, nxt);
        // -1 = not reached.
        if (existing >= 0 && existing <= tentative)
            continue;
        ds_grid_set(sc, NAV_SEARCH_G, nxt, tentative);
        ds_grid_set(sc, NAV_SEARCH_FROM, nxt, current);

        if (table < 0)
        {
            // Weighted straight line, mask cells.
            est = point_distance((ds_grid_get(nodes, NAV_NODE_X0, nxt) + ds_grid_get(nodes, NAV_NODE_X1, nxt)) / 2, ds_grid_get(nodes, NAV_NODE_Y, nxt), goalX, goalY);
            pri = tentative + (NAV_SEARCH_WEIGHT * est);
            entry = ds_list_size(eNode);
            ds_list_add(eNode, nxt);
            ds_list_add(eF, pri);
            ds_priority_add(open, entry, pri);
        }
        else
        {
            // Table distance: admissible; unreachable prunes the node.
            buffer_set_readpos(buf, costRow + 4 * nxt);
            raw = read_uint(buf);
            if (raw >= NAV_DIST_UNREACHABLE || raw < 0)
                continue;
            exact = raw / NAV_DIST_SCALE;
            // Unweighted (consistent).
            pri = tentative + exact;
            entry = ds_list_size(eNode);
            ds_list_add(eNode, nxt);
            ds_list_add(eF, pri);
            ds_priority_add(open, entry, pri);

            // Live-priced chain from here; cheapest becomes the incumbent.
            if (plan == NAV_PLAN_CHAIN_BOUNDS_SEARCH)
            {
                if (nxt == goal)
                    live = 0;
                else
                {
                    live = ds_grid_get(sc, NAV_SEARCH_LIVE, nxt);
                    if (live < 0)
                        live = navSearchLiveChainCost(nxt);
                }
                if (live < NAV_INF)
                {
                    live += tentative;
                    if (live < bound)
                    {
                        bound = live;
                        incumbent = nxt;
                    }
                }
            }
        }
    }
}
global.navSearchPops = pops;

if (current != goal)
    return false;
ok = navSearchReconstruct(start, goal, route);
return ok;
