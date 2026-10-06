// botFollowerFollowEdge(player, char, moved, team, hasIntel, setupGatesClosed,
//                       canDoubleJump, canRocketJump, canStickyJump)
// PathFollower.FollowEdge: steers along the edge between the current node and
// the next. Returns keys. The six query arguments are the LIVE query.
//
// The per-edge decision is PathFollower's private Steering struct, which lives
// in globals for the length of this call (global.botFollowerSteer<Field>);
// botFollowerSteerJump / botFollowerGate / botFollowerLaunch write it.
// SteerFall and Press are inlined here (marked), being a few lines each and
// run every tick.
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

// A new edge gets a fresh takeoff budget: BOT_TAKEOFF_PATIENCE is about one
// jump refusing to happen, not about how long the bot has been walking. A
// run-up belongs to the edge it was started for and goes with it.
if (current != p.botPathEdgeFrom or nxt != p.botPathEdgeTo)
{
    p.botPathTakeoffTicks = 0;
    p.botPathRunupAt = -1;
}

p.botPathEdgeFrom = current;
p.botPathEdgeTo = nxt;

// The graph is rebuilt on every map change, and a route planned against the
// old one names nodes that no longer connect.
edge = botFollowerTryFindEdge(p, current, nxt);
if (edge < 0)
{
    p.botPathEdgeUnroutableFires += 1;

    // char.y, not GoalY.
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

// Default: head for the near end of the next surface, a couple of cells in.
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
    // Already over the next surface's columns without being on it: keep going
    // its way until NodeFromWorld agrees.
    global.botFollowerSteerTargetColumn = min(max(column + dirToNext * BOT_ENTRY_LEAD, tx0), tx1);
}

etype = ds_grid_get(global.botNavEdges, NAV_EDGE_TYPE, edge);

switch (etype)
{
    case NAV_EDGE_DROPTHROUGH:
        // From the middle of the run; DOWN disables the platform entirely.
        global.botFollowerSteerTargetColumn = floor((fx0 + fx1) / 2);
        break;

    case NAV_EDGE_FALL:
        // ---- SteerFall, inlined -------------------------------------------
        // Which end cannot be re-derived here, which is why the edge carries
        // it. Off the edge the modelled trajectory is a STRAIGHT VERTICAL DROP
        // from the takeoff column, so the bot holds that column in the air -
        // the EDGE's column, not the walk-off hint past the end of the run.
        takeoff = ds_grid_get(global.botNavEdges, NAV_EDGE_TAKEOFF, edge);

        if (takeoff < 0)
        {
            // A graph cached before falls carried a takeoff: the old guess.
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
        // A walk edge is walked; a move box carries the bot once on one.
        break;

    default:
        // A graph from a newer generator degrades into a counted number rather
        // than silently flying an arc nobody modelled.
        p.botPathUnsupportedEdgeTicks += 1;
        break;
}

keys = 0;
if (etype == NAV_EDGE_DROPTHROUGH)
{
    if (abs(column - global.botFollowerSteerTargetColumn) <= BOT_ENTRY_LEAD)
        keys = BOT_KEY_DOWN;
}

// The steering target is a direction hint, not a place to stop: once on it,
// keep nudging the way the next node lies and let NodeFromWorld decide.
targetX = global.botFollowerSteerTargetColumn * NAV_CELL_SIZE + NAV_BOX_W * NAV_CELL_SIZE / 2;

if (px < targetX - BOT_STEER_TOL)
    keys = keys | BOT_KEY_RIGHT;
else if (px > targetX + BOT_STEER_TOL)
    keys = keys | BOT_KEY_LEFT;
else if (dirToNext > 0)
    keys = keys | BOT_KEY_RIGHT;
else if (dirToNext < 0)
    keys = keys | BOT_KEY_LEFT;

// Braking on the ground and the in-flight tracker both REPLACE the steering
// keys rather than adding to them.
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

    // Behind the plan is a press forward, ahead of it a press back. On a
    // ROCKET arc each press is also gated on speed along the jump (TrackGate);
    // which branch is catching up depends on the direction, and TrackAlong
    // already carries that sign. GM8's `or` does not short-circuit, but every
    // operand here is a plain read.
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

// Before the jump press and before the stuck counter: the reference's
// `return 0`, no keys at all.
if (global.botFollowerSteerAbandon)
{
    p.botPathRocketFire = false;

    // And the setup, or a bot that abandoned mid-countdown detonates under a
    // route it is no longer following.
    p.botPathMineFire = false;
    p.botPathMineDetonate = false;
    p.botPathStickySetup = -1;
    p.botPathStuckTicks = 0;
    return 0;
}

// ---- Press, inlined -------------------------------------------------------
// Jump is edge-triggered (Begin Step jumps on pressedKeys & $80), so a bot
// holding JUMP jumps once and never again. Alternating gives a bot that still
// wants to jump a fresh press every other tick.
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

// Out of the per-edge steering and onto the state, which is what
// botFollowerApplyLaunch reads.
p.botPathRocketFire = global.botFollowerSteerRocketFire;
p.botPathMineFire = global.botFollowerSteerMineFire;
p.botPathMineDetonate = global.botFollowerSteerMineDetonate;

// Gated on actually pressing something, unlike the arrival branch's: a bot
// standing on its target waiting for a jump window would otherwise report
// itself stuck.
if (!moved and keys != 0)
    p.botPathStuckTicks += 1;
else
    p.botPathStuckTicks = 0;

if (p.botPathStuckTicks >= BOT_STUCK_TICKS)
{
    p.botPathStuckFires += 1;
    botPathBlacklistEdge(p, current, nxt);

    // char.y, not GoalY.
    botFollowerPlan(p, px, char.y, argument3, argument4, argument5, argument6, argument7, argument8);
    return 0;
}

return keys;
