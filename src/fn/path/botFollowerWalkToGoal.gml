// botFollowerWalkToGoal(player, x, y, hspeed, onGround, moved, team, hasIntel,
//                       setupGatesClosed, canDoubleJump, canRocketJump,
//                       canStickyJump)
// PathFollower.WalkToGoal: on the route's last node, walks to the goal and
// stops. Returns keys. Inside BOT_ARRIVE_TOL it brakes; arrival needs ground
// and |hspeed| < 1.
var p, px, py, hs, onGround, moved, last, gx, keys, brake;
p = argument0;
px = argument1;
py = argument2;
hs = argument3;
onGround = argument4;
moved = argument5;

p.botPathEdgeFrom = -1;
p.botPathEdgeTo = -1;

last = ds_list_find_value(p.botPathPath, ds_list_size(p.botPathPath) - 1);

// Goal x clamped into the node's span (ColumnWorldX inlined).
gx = max(
    ds_grid_get(global.botNavNodes, NAV_NODE_X0, last) * NAV_CELL_SIZE + NAV_BOX_W * NAV_CELL_SIZE / 2,
    min(ds_grid_get(global.botNavNodes, NAV_NODE_X1, last) * NAV_CELL_SIZE + NAV_BOX_W * NAV_CELL_SIZE / 2,
        p.botPathGoalX));

// A stale route's end is not an arrival.
if (abs(px - gx) <= BOT_ARRIVE_TOL and !p.botPathPathStale)
{
    if (onGround and abs(hs) < 1)
    {
        p.botPathArrived = true;
        p.botPathArrivedAt = global.botTick;
        p.botPathHasGoal = false;

        // Before freeing the path: the edges are found through it.
        botOccupancyRemove(p);
        botPathFreePath(p);
        return 0;
    }

    brake = 0;
    if (hs > 1)
        brake = BOT_KEY_LEFT;
    else if (hs < -1)
        brake = BOT_KEY_RIGHT;

    p.botPathStuckTicks = 0;
    return brake;
}

if (px < gx)
    keys = BOT_KEY_RIGHT;
else
    keys = BOT_KEY_LEFT;

// A direction is always pressed here.
if (!moved)
    p.botPathStuckTicks += 1;
else
    p.botPathStuckTicks = 0;

if (p.botPathStuckTicks >= BOT_STUCK_TICKS)
{
    p.botPathStuckFires += 1;

    botFollowerPlan(p, px, py, argument6, argument7, argument8, argument9, argument10, argument11);
    return 0;
}

return keys;
