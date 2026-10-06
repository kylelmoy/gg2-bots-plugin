// botObjectiveTryResolve(player, found, goalX, goalY, isSpot, mustTouch, offset):
// BotObjective.TryResolve - resolves a decided goal (botObjectiveDecide's BotGoal,
// field by field) to a nav node's own stand position. Returns whether it resolved
// (global.botRet); the point is global.botRetX / global.botRetY.
// `player` is unused (the C# method is on the per-bot BotObjective, whose only
// state here is the graph, which is global); isSpot and mustTouch are unused by
// the C# too, and passed so a caller can hand the goal over whole.
//
// Every objective is an OBJECT position, and map objects are not anchored the
// way a character is, so: snap the objective to a node (searching downward),
// then re-derive the goal from that node's own stand position, which the
// follower then resolves back to the same node.
//
// The objective's own node is resolved FIRST and the offset only earns its way
// in: snapping an already-offset position can step off the objective's
// platform and land several storeys down. An offset snap is accepted only within
// a body's height (BOX_H cells) of the objective's own node - "the same level",
// so a spread can still cross a step. The column is then whichever of the
// node's columns is nearest the goal's x.
var goalFound, goalX, goalY, spreadX, baseX, node, off, standNode, standOff, x0, x1, col, ok;
goalFound = argument1;
goalX = argument2;
goalY = argument3;
spreadX = argument6;

global.botRetX = 0;
global.botRetY = 0;

if (!goalFound)
    return false;
if (!global.botNavReady)
    return false;

baseX = goalX - spreadX;
node = navGraphSnapObjective(baseX, goalY);
if (node < 0)
{
    global.botRetX = 0;
    global.botRetY = 0;
    return false;
}

standNode = (ds_grid_get(global.botNavNodes, NAV_NODE_Y, node) + NAV_BOX_H) * NAV_CELL_SIZE - BOT_OBJ_FEET_OFFSET;

if (spreadX != 0)
{
    off = navGraphSnapObjective(goalX, goalY);
    ok = false;
    if (off >= 0)
    {
        standOff = (ds_grid_get(global.botNavNodes, NAV_NODE_Y, off) + NAV_BOX_H) * NAV_CELL_SIZE - BOT_OBJ_FEET_OFFSET;
        ok = (abs(standOff - standNode) <= NAV_BOX_H * NAV_CELL_SIZE);
    }
    if (ok)
    {
        node = off;
        standNode = standOff;
    }
    else
        spreadX = 0;
}

x0 = ds_grid_get(global.botNavNodes, NAV_NODE_X0, node);
x1 = ds_grid_get(global.botNavNodes, NAV_NODE_X1, node);
col = floor((baseX + spreadX) / NAV_CELL_SIZE) - (NAV_BOX_W div 2);
col = min(max(col, x0), x1);

global.botRetX = col * NAV_CELL_SIZE + NAV_BOX_W * NAV_CELL_SIZE / 2;
global.botRetY = standNode;
return true;
