// botFollowerSteerJump(player, char, edge, current, next, column, dirToNext,
//                      team, hasIntel, setupGatesClosed, canDoubleJump,
//                      canRocketJump, canStickyJump)
// PathFollower.SteerJump: any jump arc - approach and gate on the ground, a
// position tracker in the air. Writes global.botFollowerSteer*; live query.
// Approach is inlined (marked).
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

// Takeoff from the edge; node end only if the edge has none.
takeoff = ds_grid_get(edges, NAV_EDGE_TAKEOFF, edge);
if (takeoff < 0)
{
    if (dirToNext >= 0)
        takeoff = ds_grid_get(nodes, NAV_NODE_X1, current);
    else
        takeoff = ds_grid_get(nodes, NAV_NODE_X0, current);
}

needVx = ds_grid_get(edges, NAV_EDGE_BUCKET, edge);
flightTicks = ds_grid_get(edges, NAV_EDGE_TICKS, edge);
jumpDistance = needVx * flightTicks;

// Side of the takeoff column the landing is on.
jumpDir = dirToNext;
if (tx0 > takeoff)
    jumpDir = 1;
else if (tx1 < takeoff)
    jumpDir = -1;

// Signed speed along the jump.
along = char.hspeed * jumpDir;
etype = ds_grid_get(edges, NAV_EDGE_TYPE, edge);
isRocket = etype == NAV_EDGE_ROCKETJUMP;

if (!char.onground)
{
    p.botPathAirTicks += 1;

    // Dud: no blast (moveStatus != 1) after tick one; abandon to off-route.
    if ((isRocket or etype == NAV_EDGE_STICKYJUMP)
        and p.botPathAirTicks > 1
        and char.moveStatus != 1)
    {
        if (p.botPathAirTicks == 2)
            p.botPathRocketDuds += 1;

        global.botFollowerSteerAbandon = true;
        return 0;
    }

    // Double jump's second press, once, at the edge's REJUMP tick (-1: none).
    rejump = ds_grid_get(edges, NAV_EDGE_REJUMP, edge);
    if (rejump >= 0 and !p.botPathRejumped and qDJ
        and p.botPathAirTicks >= rejump)
    {
        global.botFollowerSteerWantJump = true;
        p.botPathRejumped = true;
        p.botPathDoubleJumps += 1;
    }

    // Planned x now, clamped at the landing.
    global.botFollowerSteerTrackX = takeoff * NAV_CELL_SIZE + NAV_BOX_W * NAV_CELL_SIZE / 2
        + jumpDir * min(jumpDistance, needVx * p.botPathAirTicks);

    global.botFollowerSteerTracking = true;

    // Rocket arcs (no friction) gate presses on speed.
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
        // Run-up: reach the mark, then head for the takeoff.
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

    // Brake to the arc's speed only within BOT_RUNUP_CELLS of takeoff.
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
