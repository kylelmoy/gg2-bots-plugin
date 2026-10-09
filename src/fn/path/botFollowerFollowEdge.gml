// botFollowerFollowEdge(player, char, moved, team, hasIntel, setupGatesClosed,
//                       canDoubleJump, canRocketJump, canStickyJump)
// PathFollower.FollowEdge: steers along the current edge. Returns keys; live
// query. The Steering struct is global.botFollowerSteer<Field> for this call.
// SteerFall and Press are inlined (marked).
var p, char, moved, current, nxt, edge, etype, px, hs, onGround;
var fx0, fx1, tx0, tx1, column, dirToNext, keys, targetX, takeoff, nodes;
p = argument0;
char = argument1;
moved = argument2;

px = char.x;
hs = char.hspeed;
onGround = char.onground;

current = ds_list_find_value(p.botPathPath, p.botPathPathAt);
nxt = ds_list_find_value(p.botPathPath, p.botPathPathAt + 1);

// New edge: reset takeoff budget and run-up.
if (current != p.botPathEdgeFrom or nxt != p.botPathEdgeTo)
{
    p.botPathTakeoffTicks = 0;
    p.botPathRunupAt = -1;
}

p.botPathEdgeFrom = current;
p.botPathEdgeTo = nxt;

edge = botFollowerTryFindEdge(p, current, nxt);
if (edge < 0)
{
    p.botPathEdgeUnroutableFires += 1;

    botFollowerPlan(p, px, char.y, argument3, argument4, argument5, argument6, argument7, argument8);
    return 0;
}

nodes = global.botNavNodes;
fx0 = ds_grid_get(nodes, NAV_NODE_X0, current);
fx1 = ds_grid_get(nodes, NAV_NODE_X1, current);
tx0 = ds_grid_get(nodes, NAV_NODE_X0, nxt);
tx1 = ds_grid_get(nodes, NAV_NODE_X1, nxt);

// NavGraph.AnchorColumn, inlined.
column = floor(px / NAV_CELL_SIZE) - NAV_BOX_W / 2;

if (tx0 + tx1 > fx0 + fx1)
    dirToNext = 1;
else if (tx0 + tx1 < fx0 + fx1)
    dirToNext = -1;
else
    dirToNext = 0;

// default(Steering)
global.botFollowerSteerTargetColumn = 0;
global.botFollowerSteerBraking = false;
global.botFollowerSteerWantJump = false;
global.botFollowerSteerTracking = false;
global.botFollowerSteerTrackX = 0;
global.botFollowerSteerAbandon = false;
global.botFollowerSteerTrackGate = false;
global.botFollowerSteerTrackNeedVx = 0;
global.botFollowerSteerTrackAlong = 0;
global.botFollowerSteerTrackDir = 0;
global.botFollowerSteerRocketFire = false;
global.botFollowerSteerMineFire = false;
global.botFollowerSteerMineDetonate = false;

// Default: a few cells into the near end of the next surface.
if (column < tx0)
{
    global.botFollowerSteerTargetColumn = min(tx1, tx0 + BOT_ENTRY_LEAD);
}
else if (column > tx1)
{
    global.botFollowerSteerTargetColumn = max(tx0, tx1 - BOT_ENTRY_LEAD);
}
else
{
    // Over its columns but not on it: keep going.
    global.botFollowerSteerTargetColumn = min(max(column + dirToNext * BOT_ENTRY_LEAD, tx0), tx1);
}

etype = ds_grid_get(global.botNavEdges, NAV_EDGE_TYPE, edge);

switch (etype)
{
    case NAV_EDGE_DROPTHROUGH:
        // DOWN from mid-run.
        global.botFollowerSteerTargetColumn = floor((fx0 + fx1) / 2);
        break;

    case NAV_EDGE_FALL:
        // ---- SteerFall, inlined -------------------------------------------
        // In the air, hold the edge's takeoff column (a vertical drop).
        takeoff = ds_grid_get(global.botNavEdges, NAV_EDGE_TAKEOFF, edge);

        if (takeoff < 0)
        {
            // Edge has no takeoff: guess from the node ends.
            if (fx1 + 1 >= tx0 and fx1 + 1 <= tx1)
                takeoff = fx1 + 1;
            else
                takeoff = fx0 - 1;
        }

        if (takeoff > fx1)
            global.botFollowerSteerTargetColumn = fx1 + BOT_ENTRY_LEAD;
        else
            global.botFollowerSteerTargetColumn = fx0 - BOT_ENTRY_LEAD;

        if (!onGround)
        {
            global.botFollowerSteerTrackX = takeoff * NAV_CELL_SIZE + NAV_BOX_W * NAV_CELL_SIZE / 2;
            global.botFollowerSteerTracking = true;
            p.botPathFlyingEdge = true;
        }
        // --------------------------------------------------------------------
        break;

    case NAV_EDGE_JUMP:
    case NAV_EDGE_DOUBLEJUMP:
    case NAV_EDGE_ROCKETJUMP:
    case NAV_EDGE_STICKYJUMP:
        botFollowerSteerJump(p, char, edge, current, nxt, column, dirToNext,
            argument3, argument4, argument5, argument6, argument7, argument8);
        break;

    case NAV_EDGE_WALK:
    case NAV_EDGE_MOVEBOX:
        break;

    default:
        // Unknown edge type: counted, not flown.
        p.botPathUnsupportedEdgeTicks += 1;
        break;
}

keys = 0;
if (etype == NAV_EDGE_DROPTHROUGH)
{
    if (abs(column - global.botFollowerSteerTargetColumn) <= BOT_ENTRY_LEAD)
        keys = BOT_KEY_DOWN;
}

// Target is a direction hint: once on it, keep pressing toward the next node.
targetX = global.botFollowerSteerTargetColumn * NAV_CELL_SIZE + NAV_BOX_W * NAV_CELL_SIZE / 2;

if (px < targetX - BOT_STEER_TOL)
    keys = keys | BOT_KEY_RIGHT;
else if (px > targetX + BOT_STEER_TOL)
    keys = keys | BOT_KEY_LEFT;
else if (dirToNext > 0)
    keys = keys | BOT_KEY_RIGHT;
else if (dirToNext < 0)
    keys = keys | BOT_KEY_LEFT;

// Braking and tracking replace the steering keys.
if (global.botFollowerSteerBraking)
{
    keys = keys & ~(BOT_KEY_LEFT | BOT_KEY_RIGHT);

    if (hs > 0)
        keys = keys | BOT_KEY_LEFT;
    else if (hs < 0)
        keys = keys | BOT_KEY_RIGHT;
}
else if (global.botFollowerSteerTracking)
{
    keys = keys & ~(BOT_KEY_LEFT | BOT_KEY_RIGHT);

    // Press toward TrackX; with TrackGate, only if speed along the jump allows.
    if (px < global.botFollowerSteerTrackX - 1)
    {
        if (!global.botFollowerSteerTrackGate
            or (global.botFollowerSteerTrackDir > 0 and global.botFollowerSteerTrackAlong < global.botFollowerSteerTrackNeedVx)
            or (global.botFollowerSteerTrackDir < 0 and global.botFollowerSteerTrackAlong > global.botFollowerSteerTrackNeedVx))
        {
            keys = keys | BOT_KEY_RIGHT;
        }
    }
    else if (px > global.botFollowerSteerTrackX + 1)
    {
        if (!global.botFollowerSteerTrackGate
            or (global.botFollowerSteerTrackDir > 0 and global.botFollowerSteerTrackAlong > global.botFollowerSteerTrackNeedVx)
            or (global.botFollowerSteerTrackDir < 0 and global.botFollowerSteerTrackAlong < global.botFollowerSteerTrackNeedVx))
        {
            keys = keys | BOT_KEY_LEFT;
        }
    }
}

// Abandon: no keys, before the jump press and stuck counter.
if (global.botFollowerSteerAbandon)
{
    p.botPathRocketFire = false;

    // Also cancel any sticky setup.
    p.botPathMineFire = false;
    p.botPathMineDetonate = false;
    p.botPathStickySetup = -1;
    p.botPathStuckTicks = 0;
    return 0;
}

// ---- Press, inlined -------------------------------------------------------
// Jump is edge-triggered: alternate to re-press every other tick.
if (!global.botFollowerSteerWantJump)
{
    p.botPathJumpHeld = false;
}
else if (p.botPathJumpHeld)
{
    p.botPathJumpHeld = false;
}
else
{
    p.botPathJumpHeld = true;
    keys = keys | BOT_KEY_JUMP;
}
// ---------------------------------------------------------------------------

// For botFollowerApplyLaunch.
p.botPathRocketFire = global.botFollowerSteerRocketFire;
p.botPathMineFire = global.botFollowerSteerMineFire;
p.botPathMineDetonate = global.botFollowerSteerMineDetonate;

// Stuck only while pressing something.
if (!moved and keys != 0)
    p.botPathStuckTicks += 1;
else
    p.botPathStuckTicks = 0;

if (p.botPathStuckTicks >= BOT_STUCK_TICKS)
{
    p.botPathStuckFires += 1;
    botPathBlacklistEdge(p, current, nxt);

    botFollowerPlan(p, px, char.y, argument3, argument4, argument5, argument6, argument7, argument8);
    return 0;
}

return keys;
