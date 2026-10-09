// botFollowerSetMap(player) - path half of ScriptedBot.SetMap: drops the
// occupancy counts, route, goal, blacklist and lane, all graph-specific.
var p;
p = argument0;

// Before freeing the path: the edges are found through it.
botOccupancyRemove(p);

botPathFreePath(p);
p.botPathHasGoal = false;
ds_map_clear(p.botPathBlacklist);
ds_queue_clear(p.botPathBlacklistOrder);

p.botFollowerLane = -1;
