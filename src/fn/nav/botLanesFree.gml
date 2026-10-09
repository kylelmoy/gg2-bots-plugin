// botLanesFree(): drop derived lanes (botLanesCount 0). Called on every map
// load.
if (global.botLanesCost >= 0)
    ds_grid_destroy(global.botLanesCost);
global.botLanesCost = -1;
global.botLanesCount = 0;
