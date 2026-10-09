// botGoalSpotReach(fromNode, query): BotGoalSpot.Reach - fills
// global.botGoalSpotReachGrid (1 x nodes, 1 = reachable) with nodes routable
// from fromNode under query (BOT_SPOT_Q_* bits).
// Departure: one cache shared by all bots, keyed on (from, query, map gen, node
// count). Inlines NavGraph.EdgeRoutable; must match navGraphEdgeRoutable
// (docs/departures/objective.md).
var from, query, gen, count, reach, queue, isBlue, hasIntel, setupClosed, canDj, canRj, canSj;
var n, e, last, k, toNode, gate, etype, pass;
from = argument0;
query = argument1;

gen = 0;
if (variable_global_exists("botSpawnsGen"))
    gen = global.botSpawnsGen;
count = global.botNavNodeCount;

if (!variable_global_exists("botGoalSpotReachGrid"))
{
    global.botGoalSpotReachGrid = ds_grid_create(1, max(1, count));
    global.botGoalSpotQueue = ds_queue_create();
    global.botGoalSpotReachFrom = -1;
    global.botGoalSpotReachQuery = -1;
    global.botGoalSpotReachGen = -1;
    global.botGoalSpotReachCount = -1;
}

if (from == global.botGoalSpotReachFrom and query == global.botGoalSpotReachQuery
    and gen == global.botGoalSpotReachGen and count == global.botGoalSpotReachCount)
    return;

global.botGoalSpotReachFrom = from;
global.botGoalSpotReachQuery = query;
global.botGoalSpotReachGen = gen;
global.botGoalSpotReachCount = count;

reach = global.botGoalSpotReachGrid;
queue = global.botGoalSpotQueue;
if (ds_grid_height(reach) != max(1, count))
    ds_grid_resize(reach, 1, max(1, count));
ds_grid_clear(reach, 0);
ds_queue_clear(queue);

isBlue = ((query & BOT_SPOT_Q_BLUE) != 0);
hasIntel = ((query & BOT_SPOT_Q_INTEL) != 0);
setupClosed = ((query & BOT_SPOT_Q_SETUP) != 0);
canDj = ((query & BOT_SPOT_Q_DJ) != 0);
canRj = ((query & BOT_SPOT_Q_RJ) != 0);
canSj = ((query & BOT_SPOT_Q_SJ) != 0);

ds_grid_set(reach, 0, from, 1);
ds_queue_enqueue(queue, from);

while (!ds_queue_empty(queue))
{
    n = ds_queue_dequeue(queue);
    e = ds_grid_get(global.botNavEdgeStart, 0, n);
    if (e < 0)
        continue;
    last = e + ds_grid_get(global.botNavEdgeStart, 1, n);
    for (k = e; k < last; k += 1)
    {
        toNode = ds_grid_get(global.botNavEdges, NAV_EDGE_TO, k);
        if (ds_grid_get(reach, 0, toNode) != 0)
            continue;

        gate = ds_grid_get(global.botNavEdges, NAV_EDGE_GATE, k);
        pass = false;
        if (gate == NAV_GATE_NONE)
            pass = true;
        else if (gate == NAV_GATE_TEAM_RED)
            pass = (!isBlue and !hasIntel);
        else if (gate == NAV_GATE_TEAM_BLUE)
            pass = (isBlue and !hasIntel);
        else if (gate == NAV_GATE_INTEL_RED)
            pass = (!isBlue or !hasIntel);
        else if (gate == NAV_GATE_INTEL_BLUE)
            pass = (isBlue or !hasIntel);
        else if (gate == NAV_GATE_SETUP)
            pass = !setupClosed;
        if (!pass)
            continue;

        etype = ds_grid_get(global.botNavEdges, NAV_EDGE_TYPE, k);
        if (etype == NAV_EDGE_DOUBLEJUMP and !canDj)
            continue;
        if (etype == NAV_EDGE_STICKYJUMP and !canSj)
            continue;
        if (etype == NAV_EDGE_ROCKETJUMP and !canRj)
            continue;

        ds_grid_set(reach, 0, toNode, 1);
        ds_queue_enqueue(queue, toNode);
    }
}
