// botFollowerSteerJump(player, char, edge, current, next, column, dirToNext,
//                      team, hasIntel, setupGatesClosed, canDoubleJump,
//                      canRocketJump, canStickyJump)
// PathFollower.SteerJump: a jump, double-jump, rocket-jump or sticky-jump arc -
// the takeoff gate on the ground, the position tracker in the air. Writes the
// Steering globals (global.botFollowerSteer*). The query is the LIVE one.
//
// An arc is flown as a TRAJECTORY, not as a speed. The generator validated
// one arc - leave the takeoff column, cover Bucket px of ground a tick, be over
// the landing when it comes down - and tracking a POSITION corrects both a
// slow start and any nudge in the air: behind is a reason to press, ahead a
// reason to brake. Measured: 12-19% of jumps landed on the aimed-at node
// before, 100% after.
//
// PathFollower.Approach is inlined below (marked); it runs every tick of the
// walk to the takeoff column.
var p, char, edge, current, nxt, column, dirToNext, qDJ, edges, nodes;
var tx0, tx1, takeoff, needVx, flightTicks, jumpDistance, jumpDir, along;
var etype, isRocket, rejump;
p = argument0;
char = argument1;
edge = argument2;
current = argument3;
nxt = argument4;
column = argument5;
dirToNext = argument6;
qDJ = argument10;

edges = global.botNavEdges;
nodes = global.botNavNodes;
tx0 = ds_grid_get(nodes, NAV_NODE_X0, nxt);
tx1 = ds_grid_get(nodes, NAV_NODE_X1, nxt);

// The takeoff column is carried ON THE EDGE because the generator SEARCHED for
// it; re-deriving it from the node's own columns would jump from a column the
// build already rejected.
takeoff = ds_grid_get(edges, NAV_EDGE_TAKEOFF, edge);
if (takeoff < 0)
{
    if (dirToNext >= 0)
        takeoff = ds_grid_get(nodes, NAV_NODE_X1, current);
    else
        takeoff = ds_grid_get(nodes, NAV_NODE_X0, current);
}

// Ticks are counted rather than read off vspeed, which pins at 10 once the
// fall reaches terminal velocity.
needVx = ds_grid_get(edges, NAV_EDGE_BUCKET, edge);
flightTicks = ds_grid_get(edges, NAV_EDGE_TICKS, edge);
jumpDistance = needVx * flightTicks;

// The generator's own direction: the side of the takeoff column the landing is
// on. A wide surface can straddle the midpoint test.
jumpDir = dirToNext;
if (tx0 > takeoff)
    jumpDir = 1;
else if (tx1 < takeoff)
    jumpDir = -1;

// Speed ALONG THE JUMP, not speed: `abs(hspeed) <= needVx + 1` is satisfied by
// a bot drifting the wrong way at 2 px/tick.
along = char.hspeed * jumpDir;
etype = ds_grid_get(edges, NAV_EDGE_TYPE, edge);
isRocket = etype == NAV_EDGE_ROCKETJUMP;

if (!char.onground)
{
    p.botPathAirTicks += 1;

    // The rocket (or mine) did not go off, so this is not the arc that was
    // planned: moveStatus 1 is set by the blast itself, and without it this is
    // an ORDINARY jump. Abandon (no keys) and let the landing be adjudicated
    // by the off-route machinery, which gives the edge one retry.
    // `AirTicks > 1`, not `>= 1`: the blast lands in the same tick's
    // simulation as the takeoff press, so tick one is always moveStatus 0.
    if ((isRocket or etype == NAV_EDGE_STICKYJUMP)
        and p.botPathAirTicks > 1
        and char.moveStatus != 1)
    {
        // Once per attempt: tick two is the first that can see a dud.
        if (p.botPathAirTicks == 2)
            p.botPathRocketDuds += 1;

        global.botFollowerSteerAbandon = true;
        return 0;
    }

    // The second impulse on a double-jump arc, at the tick the generator
    // proved it (-1 on every other kind). A PRESS, not a hold; a once-only
    // flag rather than an equality on the tick. CanDoubleJump is the live
    // query's: a route outlives the plan that made it.
    rejump = ds_grid_get(edges, NAV_EDGE_REJUMP, edge);
    if (rejump >= 0 and !p.botPathRejumped and qDJ
        and p.botPathAirTicks >= rejump)
    {
        global.botFollowerSteerWantJump = true;
        p.botPathRejumped = true;
        p.botPathDoubleJumps += 1;
    }

    // Where the plan says to be now, clamped at the landing so a late bot
    // keeps pressing toward it rather than aiming past it.
    global.botFollowerSteerTrackX = takeoff * NAV_CELL_SIZE + NAV_BOX_W * NAV_CELL_SIZE / 2
        + jumpDir * min(jumpDistance, needVx * p.botPathAirTicks);

    global.botFollowerSteerTracking = true;

    // The rocket arc's tracker is SPEED-GATED where every other arc's is not:
    // with no friction under it, a press past the arc's own vx gains nothing
    // and is what made the real tracker limit-cycle.
    global.botFollowerSteerTrackGate = isRocket;
    global.botFollowerSteerTrackNeedVx = needVx;
    global.botFollowerSteerTrackAlong = along;
    global.botFollowerSteerTrackDir = jumpDir;

    p.botPathFlyingEdge = true;
    return 0;
}

if (abs(column - takeoff) > BOT_JUMP_LEAD)
{
    // ---- Approach, inlined ------------------------------------------------
    if (p.botPathRunupAt >= 0)
    {
        // Backing up: walk to the mark, then turn round and accelerate at the
        // takeoff column over the whole distance just walked. Arrival is
        // BOT_ENTRY_LEAD rather than exact, as every other target column is.
        if (abs(column - p.botPathRunupAt) <= BOT_ENTRY_LEAD)
        {
            p.botPathRunupAt = -1;
            global.botFollowerSteerTargetColumn = takeoff;
        }
        else
        {
            global.botFollowerSteerTargetColumn = p.botPathRunupAt;
        }

        return 0;
    }

    // Approaching: arrive at about the arc's speed rather than sprinting at
    // the gate - but only over the last BOT_RUNUP_CELLS (bleeding speed for the
    // whole leg cost 30-50% on the valley scenarios).
    if (along > needVx + BOT_JUMP_VTOL
        and abs(column - takeoff) <= BOT_RUNUP_CELLS)
    {
        global.botFollowerSteerBraking = true;
    }
    else
    {
        global.botFollowerSteerTargetColumn = takeoff;
    }
    // -----------------------------------------------------------------------
    return 0;
}

botFollowerGate(p, char, edge, current, nxt, takeoff, jumpDir, along, column,
    argument7, argument8, argument9, argument10, argument11, argument12);
return 0;
