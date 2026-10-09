// botFollowerSetGoal(player, worldX, worldY) - PathFollower.SetGoal (plus
// ScriptedBot.SetGoal's graph test): keeps the goal snapped onto the graph,
// marks the old route stale and plans next tick. Returns whether a goal was
// set.
var p, wx, wy, node, gx, gy;
p = argument0;
wx = argument1;
wy = argument2;

// ScriptedBot.SetGoal: `_graph is not null && ...`
if (!global.botNavReady)
    return false;

node = navGraphSnapObjective(wx, wy);
gx = global.botRetGoalX;
gy = global.botRetGoalY;
if (node < 0)
    return false;

p.botPathGoalX = gx;
p.botPathGoalY = gy;
p.botPathHasGoal = true;
p.botPathArrived = false;
p.botPathArrivedAt = -1;
p.botPathPathStale = ds_list_size(p.botPathPath) > 0;

p.botPathReplanAt = 0;
p.botPathPlanFailUntil = 0;
p.botPathGoalsSet += 1;
return true;
