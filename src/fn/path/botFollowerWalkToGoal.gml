// botFollowerWalkToGoal(player, x, y, hspeed, onGround, moved, team, hasIntel,
//                       setupGatesClosed, canDoubleJump, canRocketJump,
//                       canStickyJump)
// PathFollower.WalkToGoal: on the last node of the route, walk the rest of the
// way to the goal along the surface, and stop on it. Returns keys.
//
// Being within tolerance of the goal is not the same as stopping there: GG2
// keeps a character's horizontal speed for about ten ticks after the keys come
// off, so declaring arrival on position alone coasts it 30-40 px past. Inside
// the band the bot BRAKES (presses against its motion), and only counts as
// arrived once on the ground and actually stopped; the speed floor of 1 keeps
// the brake from becoming a press back the other way.
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

// The goal clamped into the node's own span (NavGraph.ColumnWorldX inlined:
// column * NAV_CELL_SIZE + NAV_BOX_W * NAV_CELL_SIZE / 2), since NodeFromWorld
// resolves a goal that is NEAR a surface rather than exactly on it.
gx = max(
    ds_grid_get(global.botNavNodes, NAV_NODE_X0, last) * NAV_CELL_SIZE + NAV_BOX_W * NAV_CELL_SIZE / 2,
    min(ds_grid_get(global.botNavNodes, NAV_NODE_X1, last) * NAV_CELL_SIZE + NAV_BOX_W * NAV_CELL_SIZE / 2,
        p.botPathGoalX));

// PathStale disables the whole band: the route ends where the bot was sent
// BEFORE, and reaching it is not an arrival at anything.
if (abs(px - gx) <= BOT_ARRIVE_TOL and !p.botPathPathStale)
{
    if (onGround and abs(hs) < 1)
    {
        p.botPathArrived = true;
        p.botPathArrivedAt = global.botTick;
        p.botPathHasGoal = false;

        // Off the counts BEFORE the route is freed - the edges can only be
        // found through the path that is about to be cleared.
        botOccupancyRemove(p);
        botPathFreePath(p);
        return 0;
    }

    brake = 0;
    if (hs > 1)
        brake = BOT_KEY_LEFT;
    else if (hs < -1)
        brake = BOT_KEY_RIGHT;

    // Not stuck: standing still inside the band is the whole point.
    p.botPathStuckTicks = 0;
    return brake;
}

if (px < gx)
    keys = BOT_KEY_RIGHT;
else
    keys = BOT_KEY_LEFT;

// NOT gated on having pressed something, unlike the edge's: this branch always
// presses a direction, so `moved` alone is the whole question.
if (!moved)
    p.botPathStuckTicks += 1;
else
    p.botPathStuckTicks = 0;

if (p.botPathStuckTicks >= BOT_STUCK_TICKS)
{
    p.botPathStuckFires += 1;

    // y, not GoalY.
    botFollowerPlan(p, px, py, argument6, argument7, argument8, argument9, argument10, argument11);
    return 0;
}

return keys;
