// botFollowerInit(player) - PathFollower's per-bot fields on the Player.
// botFollowerScratch: search output list. botFollowerLane: lane costs for
// navSearchFind, or -1 for graph costs. Distances are shared (nav), not per
// bot.
var p;
p = argument0;
p.botFollowerScratch = ds_list_create();
p.botFollowerLane = -1;
