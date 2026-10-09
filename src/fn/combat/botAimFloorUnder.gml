// botAimFloorUnder(x, y): BotAim.FloorUnder - StandY of the surface under a
// point (downward snap), or BOT_AIM_NO_FLOOR.
var node;
if (!global.botNavReady)
    return BOT_AIM_NO_FLOOR;
node = navGraphSnapObjective(argument0, argument1);
if (node < 0)
    return BOT_AIM_NO_FLOOR;
return global.botRetGoalY;
