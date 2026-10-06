// botLanesFree(): drop the derived lanes, if any (global.botLanesCount 0,
// botLanesCosts answers -1). A lane's costs are indexed by edge row, which
// only means anything to one build of a graph, so botNavMapCheck calls this
// on every map load - ScriptedBot.SetMap's `_lanes = null`.
if (global.botLanesCost >= 0)
    ds_grid_destroy(global.botLanesCost);
global.botLanesCost = -1;
global.botLanesCount = 0;
