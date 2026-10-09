// botPathFreePath(player) - BotPathState.FreePath: clears the route, current
// edge, off-route/stuck counters and run-up. Keeps TakeoffTicks and
// RunupsStarted. Leaves occupancy: call botOccupancyRemove first.
var p;
p = argument0;
ds_list_clear(p.botPathPath);
p.botPathPathAt = 0;
p.botPathEdgeFrom = -1;
p.botPathEdgeTo = -1;
p.botPathStuckTicks = 0;
p.botPathOffPathTicks = 0;
p.botPathPathStale = false;
p.botPathRunupAt = -1;
