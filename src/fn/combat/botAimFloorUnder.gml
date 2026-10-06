// botAimFloorUnder(x, y): BotAim.FloorUnder - the stand height of the surface
// under a point, for the solver's fall clamp: navGraphSnapObjective (snap
// downward) and that node's StandY, which the snap returns as
// global.botRetGoalY. BOT_AIM_NO_FLOOR when there is no graph or nothing
// resolves - the right answer over a pit. (The C#'s graph argument is
// global.botNavReady here.)
var node;
if (!global.botNavReady)
    return BOT_AIM_NO_FLOOR;
node = navGraphSnapObjective(argument0, argument1);
if (node < 0)
    return BOT_AIM_NO_FLOOR;
return global.botRetGoalY;
