// botFollowerFree(player) - frees what botFollowerInit made.
var p;
p = argument0;
if (p.botFollowerScratch >= 0)
    ds_list_destroy(p.botFollowerScratch);
p.botFollowerScratch = -1;
