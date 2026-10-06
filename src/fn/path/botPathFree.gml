// botPathFree(player) - frees the ds_ structures botPathInit made. Called when
// the Player is destroyed. Does NOT take the route off the occupancy counts:
// call botOccupancyRemove(player) first if it may still be counted (the
// integrator's detach does, as BotPopulation does on a departure).
var p;
p = argument0;
if (p.botPathPath >= 0)
    ds_list_destroy(p.botPathPath);
if (p.botPathBlacklist >= 0)
    ds_map_destroy(p.botPathBlacklist);
if (p.botPathBlacklistOrder >= 0)
    ds_queue_destroy(p.botPathBlacklistOrder);
p.botPathPath = -1;
p.botPathBlacklist = -1;
p.botPathBlacklistOrder = -1;
