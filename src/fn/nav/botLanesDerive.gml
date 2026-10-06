// botLanesDerive(lanes, penalty): BotLanes.Derive - derive `lanes` cost fields
// for the installed graph into global.botLanesCost (a ds_grid lanes wide,
// edgeCount tall: ds_grid_get(global.botLanesCost, lane, edge)) and set
// global.botLanesCount. Returns false (and derives nothing) with no graph,
// lanes < 1 or penalty < 1. Pass BOT_LANES_PENALTY for the C#'s default.
//
// Iterative penalisation: lane 0 is the graph's own costs; lane L starts from
// lane L-1's and multiplies by penalty every edge that L-1's swept cheapest
// routes used, so each lane is pushed off every corridor its predecessors
// chose. A lane only multiplies, never removes, so reachability is the same
// on every lane. Static for the graph's lifetime - unlike occupancy, which
// reacts to this tick.
//
// COST: one Dijkstra per swept start, about NodeCount/77 starts per lane after
// the first (BOT_LANES_SWEEP_LEGS legs, every 7th start, every 11th goal) -
// a few hundred ms of interpreted GML for 4 lanes on the largest maps. Run it
// once after a map load, if at all: gg2-server's live server never derives
// lanes (only its tests do), and nothing here calls this by itself.
var lanes, penalty, e, lane, used, grid, sc, open;
lanes = argument0;
penalty = argument1;
botLanesFree();
if (!global.botNavReady)
    return false;
if (lanes < 1 || penalty < 1)
    return false;
e = max(global.botNavEdgeCount, 1);
grid = ds_grid_create(lanes, e);
// Lane 0: the graph's own cost column, copied natively.
if (global.botNavEdgeCount > 0)
    ds_grid_set_grid_region(grid, global.botNavEdges, NAV_EDGE_COST, 0, NAV_EDGE_COST, global.botNavEdgeCount - 1, 0, 0);
global.botLanesCost = grid;
global.botLanesCount = 1;

// `used` holds a MULTIPLIER per edge: 1, or penalty once a sweep marked it -
// so the whole lane is one native copy and one native multiply.
used = ds_grid_create(1, e);
sc = ds_grid_create(BOT_LANES_FIELDS, max(global.botNavNodeCount, 1));
open = ds_priority_create();
for (lane = 1; lane < lanes; lane += 1)
{
    ds_grid_clear(used, 1);
    botLanesSweep(lane - 1, used, penalty, sc, open);
    ds_grid_set_grid_region(grid, grid, lane - 1, 0, lane - 1, e - 1, lane, 0);
    ds_grid_multiply_grid_region(grid, used, 0, 0, 0, e - 1, lane, 0);
    global.botLanesCount = lane + 1;
}
ds_priority_destroy(open);
ds_grid_destroy(sc);
ds_grid_destroy(used);
return true;
