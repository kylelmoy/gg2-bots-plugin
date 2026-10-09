// botPathFree(player) - frees botPathInit's ds_ structures. Leaves occupancy:
// call botOccupancyRemove first if still counted.
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
