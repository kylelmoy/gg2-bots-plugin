// navSearchFind(start, goal, team, hasIntel, setupGatesClosed, canDoubleJump,
//               canRocketJump, canStickyJump, route, blocked, occupancy, lane,
//               table, plan)
// NavSearch.Find (navFindPath.gml) - the cheapest route from start to goal for
// this asker, by A*, or by CPD-Search when a distance table is given.
//
//   start, goal   node indices
//   team..canStickyJump   the NavQuery, as six arguments (PORTING.md)
//   route         a ds_list the caller owns: cleared, then filled with node
//                 indices, start to goal inclusive. Left empty on no route.
//   blocked       a ds_map whose KEYS are navGraphEdgeKey values to refuse (the
//                 bot's anti-thrash blacklist), or -1
//   occupancy     a ds_map edgeKey -> team-mates walking it (botOccupancyCounts),
//                 or -1. An edge in it costs (1 + BOT_OCCUPANCY_COST * count)
//                 times its cost, so a team fans out.
//   lane          a column of global.botLanesCost (botLanesCosts(lane)), or -1
//                 for the graph's own edge costs
//   table         a distance table from navDistFor, or -1 for the straight-line
//                 heuristic. Must be the asker's own (navDistFor picks it), or
//                 the heuristic overestimates and the route is wrong.
//   plan          NAV_PLAN_DECIDE_BY_CROWD (what the C# ships),
//                 NAV_PLAN_CHAIN_BOUNDS_SEARCH or NAV_PLAN_CHAIN_OR_SEARCH
// Returns whether a route was found (global.botRet). global.navSearchPops is
// how many entries were popped (diagnostic).
//
// The scratch is shared globals, not per bot: one search runs at a time.
// This is the hot spot of the plugin, so the expansion loop calls no bot/nav
// function: the edge reads, the gate/class test (navGraphEdgeRoutable's rule,
// inlined - keep the two identical), the blacklist and the crowd are all inline.
// Only a chain walk the memo has not seen calls navSearchLiveChainCost.
//
// The open set is a ds_priority with lazy deletion (GM8 has no decrease-key).
// Its values are entry numbers into global.navSearchEntryNode/EntryF, because
// a ds_priority cannot hand back the priority of the entry it pops when a
// node is queued more than once, and the incumbent test needs that f.
//
// A closed node is NOT revisited (the C#'s deliberate departure from the
// reference; with the weighted straight-line heuristic it trades a few percent
// of route cost for far fewer expansions).
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

// gScore and cameFrom to -1, closed to 0: native region writes.
ds_grid_set_region(sc, NAV_SEARCH_G, 0, NAV_SEARCH_FROM, n - 1, -1);
ds_grid_set_region(sc, NAV_SEARCH_CLOSED, 0, NAV_SEARCH_CLOSED, n - 1, 0);
ds_priority_clear(open);
ds_list_clear(eNode);
ds_list_clear(eF);

// The heuristic's target: the goal's surface midpoint, in mask cells.
goalX = (ds_grid_get(nodes, NAV_NODE_X0, goal) + ds_grid_get(nodes, NAV_NODE_X1, goal)) / 2;
goalY = ds_grid_get(nodes, NAV_NODE_Y, goal);

// The table's answer for the whole leg. Unreachable on the fully permissive
// graph means unreachable for every asker: one read instead of expanding the
// whole reachable component.
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

// The query's gate answers, once (navGraphGatePassable's table).
okRedTeam = (qTeam == TEAM_RED && !hasIntel);
okBlueTeam = (qTeam == TEAM_BLUE && !hasIntel);
okRedIntel = (qTeam == TEAM_RED || !hasIntel);
okBlueIntel = (qTeam == TEAM_BLUE || !hasIntel);
okSetup = !setupClosed;

// Hoisted: both collections are usually empty, and nothing in the loop writes
// to either.
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

// What navSearchLiveChainCost reads: this search's asker and modifiers.
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

// CPD-Search (Bono et al., IJCAI 2019) whenever a table is present: the
// incumbent is the cheapest LIVE-priced next-hop chain seen so far and `bound`
// its cost. Seeded from the start, so a chain nothing has perturbed comes back
// at the first pop with no expansion.
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
        // The whole verification in one comparison: every hop is priced at or
        // above the static edge the table used, so the chain can only EQUAL
        // the table's distance when nothing perturbed it - and then it is
        // optimal. NAV_DIST_QUANTUM: the stored distance is floored to 1/16
        // (docs/departures/nav.md).
        if (chain <= (between + NAV_DIST_QUANTUM) * (1 + NAV_SEARCH_INCUMBENT_TOLERANCE))
        {
            ok = navSearchReconstructIncumbent(start, start, goal, route);
            global.navSearchPops = 0;
            return ok;
        }
        // Perturbed: the chain is thrown away, bound stays infinite and what
        // is left is plain A* on the exact heuristic.
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

    // The goal test is on the POP: the first pop of the goal is the cheapest.
    if (current == goal)
        break;

    // The incumbent is provably as cheap as anything still to come. Tested
    // before the closed check on purpose: a stale entry's f bounds the rest
    // of the frontier just as well.
    if ((f + NAV_DIST_QUANTUM) * (1 + NAV_SEARCH_INCUMBENT_TOLERANCE) >= bound)
    {
        global.navSearchPops = pops;
        ok = navSearchReconstructIncumbent(start, incumbent, goal, route);
        return ok;
    }

    // A stale copy of a node already expanded.
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

        // navGraphEdgeRoutable, inlined: the gate on the EDGE, then the class
        // arcs, refused unless the asker can fly them.
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

        // The key is only built when somebody is going to look it up.
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
        // -1 is "not reached yet": a first visit always passes and an equal
        // cost never does.
        if (existing >= 0 && existing <= tentative)
            continue;
        ds_grid_set(sc, NAV_SEARCH_G, nxt, tentative);
        ds_grid_set(sc, NAV_SEARCH_FROM, nxt, current);

        if (table < 0)
        {
            // WEIGHTED straight line (NAV_SEARCH_WEIGHT), in mask cells.
            est = point_distance((ds_grid_get(nodes, NAV_NODE_X0, nxt) + ds_grid_get(nodes, NAV_NODE_X1, nxt)) / 2, ds_grid_get(nodes, NAV_NODE_Y, nxt), goalX, goalY);
            pri = tentative + (NAV_SEARCH_WEIGHT * est);
            entry = ds_list_size(eNode);
            ds_list_add(eNode, nxt);
            ds_list_add(eF, pri);
            ds_priority_add(open, entry, pri);
        }
        else
        {
            // The exact remaining cost on the table's graph: at or below the
            // true remainder for this asker. Unreachable from there means
            // nothing routed through it ever can be.
            buffer_set_readpos(buf, costRow + 4 * nxt);
            raw = read_uint(buf);
            if (raw >= NAV_DIST_UNREACHABLE || raw < 0)
                continue;
            exact = raw / NAV_DIST_SCALE;
            // UNWEIGHTED: an exact relaxed distance is consistent.
            pri = tentative + exact;
            entry = ds_list_size(eNode);
            ds_list_add(eNode, nxt);
            ds_list_add(eF, pri);
            ds_priority_add(open, entry, pri);

            // The table's chain from here, priced live, is a real route; the
            // cheapest such is the incumbent. Skipped under ChainOrSearch,
            // which is chosen exactly when the bound does not repay the walk.
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
