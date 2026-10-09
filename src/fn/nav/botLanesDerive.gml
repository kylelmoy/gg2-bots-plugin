// botLanesDerive(lanes, penalty): BotLanes.Derive - fill global.botLanesCost
// (ds_grid lanes x edgeCount) and global.botLanesCount. False with no graph,
// lanes < 1 or penalty < 1. BOT_LANES_PENALTY is the C# default. Lane 0 = graph
// costs; lane L = lane L-1 times penalty on edges L-1's sweep used. Costly
// (hundreds of ms); nothing calls it automatically.
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
if (global.botNavEdgeCount > 0)
    ds_grid_set_grid_region(grid, global.botNavEdges, NAV_EDGE_COST, 0, NAV_EDGE_COST, global.botNavEdgeCount - 1, 0, 0);
global.botLanesCost = grid;
global.botLanesCount = 1;

// used: per-edge multiplier, 1 or penalty.
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
