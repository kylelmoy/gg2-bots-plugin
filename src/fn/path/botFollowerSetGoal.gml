// botFollowerSetGoal(player, worldX, worldY) - PathFollower.SetGoal (and
// ScriptedBot.SetGoal's graph test): sends the bot somewhere, snapping the
// point onto the graph. Returns whether a goal was set.
//
// botSetGoal's shape: the goal is snapped downward and the SNAPPED position is
// what is kept, because a raw objective coordinate usually does not resolve to
// a node on its own. The old route is marked stale rather than freed, so the
// bot keeps moving until a plan for the new goal exists - and its arrival band
// is switched off, because reaching the end of it is not an arrival at
// anything.
//
// Event-driven: plan on the next follower tick rather than waiting out the
// timer. That is why GoalsSet is counted: a goal reissue is a search, and it
// is the majority of them.
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
