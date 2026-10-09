// botObjectiveTryResolve(player, found, goalX, goalY, isSpot, mustTouch,
// offset): BotObjective.TryResolve - snaps a botObjectiveDecide goal to a nav
// node's stand position. Returns whether it resolved (global.botRet); point in
// global.botRetX/Y. player, isSpot, mustTouch unused. The offset snap is kept
// only within NAV_BOX_H cells of the objective's own node; column clamped to
// the node, nearest goal x.
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
