// botPathFreePath(player) - BotPathState.FreePath (botPathFree.gml in the
// reference): gives up the route and everything that belongs to it - the edge
// in progress, the off-route and stuck counters, the run-up.
//
// The takeoff budget is NOT reset here (botPathFree.gml does not touch it); it
// is zeroed a moment later anyway by FollowEdge's change-of-edge test, because
// this sets EdgeFrom to -1. RunupsStarted is NOT reset either: it is keyed to
// its own edge, so a re-plan that lands on the same arc keeps the count.
//
// Does not touch occupancy: a caller that may still be counted removes the
// counts first (botOccupancyRemove), because the edges can only be found
// through the path this clears.
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
