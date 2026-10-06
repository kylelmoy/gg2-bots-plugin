// botDetach(player): the bot's Player is being destroyed. Its edges stop being
// crowded, and everything every module allocated for it is freed.
var p;
p = argument0;
botOccupancyRemove(p);
botHybridFree(p);
botObjectiveFree(p);
botCombatFree(p);
botFollowerFree(p);
botPathFree(p);
