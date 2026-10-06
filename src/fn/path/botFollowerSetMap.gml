// botFollowerSetMap(player) - the path half of ScriptedBot.SetMap: a follower,
// a route and a blacklist are all indices into ONE graph, so a bot that
// survives a map change (or a graph reload: global.botNavGeneration moved)
// carrying them holds node numbers that now mean somewhere else.
//
// The counts go with the route, removed BEFORE it is freed (the edges can only
// be found through the path). Then the route, the goal and the blacklist go,
// and the lane: it is indexed by edge position, so the integrator re-applies
// one derived for the new graph (botFollowerLane), or leaves -1 for the
// graph's own costs.
var p;
p = argument0;

botOccupancyRemove(p);

botPathFreePath(p);
p.botPathHasGoal = false;
ds_map_clear(p.botPathBlacklist);
ds_queue_clear(p.botPathBlacklistOrder);

p.botFollowerLane = -1;
