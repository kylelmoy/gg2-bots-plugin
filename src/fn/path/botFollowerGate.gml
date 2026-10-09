// botFollowerGate(player, char, edge, from, to, takeoff, jumpDir, along,
// column,
//                 team, hasIntel, setupGatesClosed, canDoubleJump,
//                 canRocketJump, canStickyJump)
// PathFollower.Gate: at the takeoff column, launch, wait or back up. Writes the
// Steering globals; live query. Departs: needVx/flightTicks read off the edge
// (GM8's 16-argument limit). Launches if along >= 0 and the reach model says
// the arc is makeable.
var p, char, edge, from, to, takeoff, jumpDir, along, column;
var qTeam, qIntel, qSetup, qDJ, qRJ, qSJ;
var edges, needVx, flightTicks, etype, landingColumn, need, lead, takeoffX;
var isRocket, isSticky, underspeed, rocketAim, floorUnder, reach;
var rocketReady, stickyReady, shortOfTakeoff;
p = argument0;
char = argument1;
edge = argument2;
from = argument3;
to = argument4;
takeoff = argument5;
jumpDir = argument6;
along = argument7;
column = argument8;
qTeam = argument9;
qIntel = argument10;
qSetup = argument11;
qDJ = argument12;
qRJ = argument13;
qSJ = argument14;

edges = global.botNavEdges;
needVx = ds_grid_get(edges, NAV_EDGE_BUCKET, edge);
flightTicks = ds_grid_get(edges, NAV_EDGE_TICKS, edge);
etype = ds_grid_get(edges, NAV_EDGE_TYPE, edge);

// Ticks at the gate; incremented only here.
p.botPathTakeoffTicks += 1;

// Run-up count is keyed to the arc, surviving a re-plan onto it.
if (p.botPathRunupsEdgeFrom != from or p.botPathRunupsEdgeTo != to)
{
    p.botPathRunupsEdgeFrom = from;
    p.botPathRunupsEdgeTo = to;
    p.botPathRunupsStarted = 0;
}

// Distance to cover, from the takeoff column (the tracker's anchor).
if (jumpDir > 0)
    landingColumn = ds_grid_get(global.botNavNodes, NAV_NODE_X0, to);
else
    landingColumn = ds_grid_get(global.botNavNodes, NAV_NODE_X1, to);
takeoffX = takeoff * NAV_CELL_SIZE + NAV_BOX_W * NAV_CELL_SIZE / 2;
need = abs((landingColumn * NAV_CELL_SIZE + NAV_BOX_W * NAV_CELL_SIZE / 2) - takeoffX);

// Minus progress inside the takeoff column, clamped to [0, one cell].
lead = jumpDir * (char.x - takeoffX);
lead = min(max(lead, 0), NAV_CELL_SIZE);
need = max(0, need - lead);

isRocket = etype == NAV_EDGE_ROCKETJUMP;

// Diagnostic only.
underspeed = along < needVx - BOT_JUMP_VTOL;

// No terrain under the muzzle (at a lip): tilt the rocket back along the run.
rocketAim = BOT_FOLLOWER_ROCKET_AIM_DEGREES;

if (isRocket)
{
    floorUnder = botFollowerFloorUnder(char.x, char.y);
    if (!floorUnder)
        rocketAim = BOT_FOLLOWER_ROCKET_AIM_DEGREES - jumpDir * BOT_FOLLOWER_LIP_AIM_DEGREES;
}

// Rocket and sticky arcs fly under moveStatus 1 physics.
isSticky = etype == NAV_EDGE_STICKYJUMP;

if (isRocket)
    reach = botRocketReach(char, needVx, flightTicks, along);
else if (isSticky)
    reach = botStickyReach(char, needVx, flightTicks, along);
else
    reach = botJumpReach(char, needVx, flightTicks, along);

// Never fly a rocket arc without the rocket.
rocketReady = true;
if (isRocket)
    rocketReady = botRocketReady(char);

// Sticky readiness gates only the start; placing the mine starts the refire.
stickyReady = true;
if (isSticky and p.botPathStickySetup < 0)
    stickyReady = botStickyReady(char);

if (rocketReady
    and stickyReady
    and along >= 0
    and along <= needVx + BOT_JUMP_VTOL
    and reach + BOT_JUMP_REACH_TOL >= need)
{
    // Sticky: place the mine, launch NAV_SJ_SETUP_TICKS later.
    if (isSticky)
    {
        if (p.botPathStickySetup < 0)
        {
            // Place the mine. StickySetup -1 = not set up.
            global.botFollowerSteerMineFire = true;
            p.botPathStickySetup = NAV_SJ_SETUP_TICKS;
        }
        else
        {
            // Decrement then test: launch exactly SjSetupTicks after placing.
            p.botPathStickySetup -= 1;

            if (p.botPathStickySetup <= 0)
            {
                // Jump and detonate on the same tick (Begin Step jumps first).
                p.botPathLaunches += 1;

                if (underspeed)
                    p.botPathLaunchesUnderspeed += 1;

                botFollowerLaunch(p, false, BOT_FOLLOWER_ROCKET_AIM_DEGREES);
                global.botFollowerSteerMineDetonate = true;
                p.botPathStickySetup = -1;
                p.botPathStickyJumps += 1;
            }
        }

        return 0;
    }

    p.botPathLaunches += 1;

    if (underspeed)
        p.botPathLaunchesUnderspeed += 1;

    botFollowerLaunch(p, isRocket, rocketAim);
}
else if (isSticky and p.botPathStickySetup >= 0)
{
    // Gate closed with a mine down: abandon.
    p.botPathStickySetup = -1;
    global.botFollowerSteerAbandon = true;
}
else if ((isRocket and !rocketReady) or (isSticky and !stickyReady))
{
    // Wait for the launcher in place. Departs: brakes instead of targeting the
    // takeoff column.
    p.botPathGateColdWeapon += 1;
    global.botFollowerSteerBraking = true;
}
else if (along > needVx + BOT_JUMP_VTOL)
{
    // Too fast for the arc.
    p.botPathGateTooFast += 1;
    global.botFollowerSteerBraking = true;
}
else
{
    // Diagnostic only.
    if (along < 0)
        p.botPathGateBackwards += 1;
    else
        p.botPathGateShort += 1;

    // Back up, unless after a run-up still short of takeoff and gaining.
    shortOfTakeoff = (takeoff - column) * jumpDir > 0;

    if (along > 0 and shortOfTakeoff and p.botPathRunupsStarted > 0)
    {
        global.botFollowerSteerTargetColumn = takeoff;
    }
    else
    {
        if (p.botPathRunupAt < 0)
        {
            p.botPathRunupAt = botJumpRunupColumn(from, takeoff, jumpDir, BOT_RUNUP_CELLS,
                qTeam, qIntel, qSetup, qDJ, qRJ, qSJ);

            p.botPathRunupsStarted += 1;
        }

        global.botFollowerSteerTargetColumn = p.botPathRunupAt;
    }
}

// Patience out: launch anyway, but blacklist a rocket arc with no rocket.
if (p.botPathTakeoffTicks >= BOT_TAKEOFF_PATIENCE)
{
    if (isRocket and !rocketReady)
    {
        botPathBlacklistEdge(p, from, to);
        p.botPathBlacklistFires += 1;
        botFollowerPlan(p, char.x, char.y, qTeam, qIntel, qSetup, qDJ, qRJ, qSJ);
        return 0;
    }

    p.botPathLaunches += 1;

    if (underspeed)
        p.botPathLaunchesUnderspeed += 1;

    global.botFollowerSteerBraking = false;

    botFollowerLaunch(p, isRocket, rocketAim);
}

return 0;
