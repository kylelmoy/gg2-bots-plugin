// botDetach(player): Player destroyed; free its occupancy and all module state.
var p;
p = argument0;
botOccupancyRemove(p);
botHybridFree(p);
botObjectiveFree(p);
botCombatFree(p);
botFollowerFree(p);
botPathFree(p);
