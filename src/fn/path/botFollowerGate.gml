// botFollowerGate(player, char, edge, from, to, takeoff, jumpDir, along, column,
//                 team, hasIntel, setupGatesClosed, canDoubleJump,
//                 canRocketJump, canStickyJump)
// PathFollower.Gate: at the takeoff column. Three ways this can go, and only
// one is a jump. Writes the Steering globals. The query is the LIVE one.
// needVx and flightTicks are re-read off the edge (they are the C#'s extra
// parameters; GM8 stops at sixteen arguments).
//
// The rule is "not moving away from the jump", not "moving at exactly the
// arc's speed": `along >= 0` admits a standstill and the reach model decides
// whether the tracker can make up the rest. Demanding the full speed at the
// gate cost 647 -> 868 and 674 -> 997 ticks with no more arrivals.
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

// Counted here and nowhere else: ticks spent AT the gate refusing to leave.
p.botPathTakeoffTicks += 1;

// Re-key the run-up count if this is a different arc from the one it was
// counting for - here rather than on the change-of-edge test, so it survives
// a re-plan onto the same edge.
if (p.botPathRunupsEdgeFrom != from or p.botPathRunupsEdgeTo != to)
{
    p.botPathRunupsEdgeFrom = from;
    p.botPathRunupsEdgeTo = to;
    p.botPathRunupsStarted = 0;
}

// How much ground this jump has to cover, measured from the takeoff COLUMN
// and not from the bot's x: the tracker's target is clamped at
// needVx * flightTicks from the anchor, a hard ceiling on how far it steers.
if (jumpDir > 0)
    landingColumn = ds_grid_get(global.botNavNodes, NAV_NODE_X0, to);
else
    landingColumn = ds_grid_get(global.botNavNodes, NAV_NODE_X1, to);
takeoffX = takeoff * NAV_CELL_SIZE + NAV_BOX_W * NAV_CELL_SIZE / 2;
need = abs((landingColumn * NAV_CELL_SIZE + NAV_BOX_W * NAV_CELL_SIZE / 2) - takeoffX);

// ...minus whatever ground the bot has already covered INSIDE the takeoff
// column. Only ever a credit, never a debit, and clamped to one cell.
lead = jumpDir * (char.x - takeoffX);
lead = min(max(lead, 0), NAV_CELL_SIZE);
need = max(0, need - lead);

isRocket = etype == NAV_EDGE_ROCKETJUMP;

// Below the arc's own takeoff speed: not a refusal, a record of how often the
// arc is flown on the model's word rather than on speed.
underspeed = along < needVx - BOT_JUMP_VTOL;

// Asked of the TERRAIN, not of the graph: aimed down, the rocket spawns at the
// body's centre, and at the lip of a run there is nothing under it - so tilt
// the blast back along the run. (The graph-based test made the sweep 38%
// worse by re-aiming arcs that already worked.)
rocketAim = BOT_FOLLOWER_ROCKET_AIM_DEGREES;

if (isRocket)
{
    floorUnder = botFollowerFloorUnder(char.x, char.y);
    if (!floorUnder)
        rocketAim = BOT_FOLLOWER_ROCKET_AIM_DEGREES - jumpDir * BOT_FOLLOWER_LIP_AIM_DEGREES;
}

// WHICH reach model, and it is not a detail: a rocket or mine jump flies under
// moveStatus 1 (control 0.65, friction 1), an ordinary arc does not.
isSticky = etype == NAV_EDGE_STICKYJUMP;

if (isRocket)
    reach = botRocketReach(char, needVx, flightTicks, along);
else if (isSticky)
    reach = botStickyReach(char, needVx, flightTicks, along);
else
    reach = botJumpReach(char, needVx, flightTicks, along);

// Jumping without the rocket is the WORST available outcome (the arc rises
// 276px where an ordinary jump rises 57), so the gate refuses to leave.
rocketReady = true;
if (isRocket)
    rocketReady = botRocketReady(char);

// The same refusal for a sticky jump - but only to START one. Once StickySetup
// is running the mine is on the ground, and placing it put the launcher on its
// refire cooldown; requiring readiness throughout closed the gate on the tick
// after every placement.
stickyReady = true;
if (isSticky and p.botPathStickySetup < 0)
    stickyReady = botStickyReady(char);

if (rocketReady
    and stickyReady
    and along >= 0
    and along <= needVx + BOT_JUMP_VTOL
    and reach + BOT_JUMP_REACH_TOL >= need)
{
    // A STICKY JUMP DOES NOT LEAVE ON THE TICK ITS GATE OPENS: the mine is
    // placed, settles, and the launch is NAV_SJ_SETUP_TICKS later.
    if (isSticky)
    {
        if (p.botPathStickySetup < 0)
        {
            // Phase one: put the mine down and stand still. -1, not 0, is
            // "not set up".
            global.botFollowerSteerMineFire = true;
            p.botPathStickySetup = NAV_SJ_SETUP_TICKS;
        }
        else
        {
            // Decrement THEN test, so the launch lands exactly SjSetupTicks
            // after the placing tick.
            // While still above zero the mine is settling: press nothing more.
            p.botPathStickySetup -= 1;

            if (p.botPathStickySetup <= 0)
            {
                // Phase two, both presses THIS tick: Begin Step runs its jump
                // branch before its right-click branch, so the blast lands on
                // top of `vspeed = -jumpStrength`.
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
    // The gate closed with a mine already down: abandon rather than stand on a
    // live mine waiting for a window that has moved.
    p.botPathStickySetup = -1;
    global.botFollowerSteerAbandon = true;
}
else if ((isRocket and !rocketReady) or (isSticky and !stickyReady))
{
    // Waiting for the launcher, and NOT falling through to the run-up: refire
    // is 30 ticks against the 60-tick patience, so stand on the takeoff column
    // and wait. BRAKING, where the reference aims at the takeoff column: this
    // port's default steering is a direction hint that presses on even on its
    // target, which the stuck detector read as stuck at tick 12.
    p.botPathGateColdWeapon += 1;
    global.botFollowerSteerBraking = true;
}
else if (along > needVx + BOT_JUMP_VTOL)
{
    // Faster than the arc allows: with no key held GG2 sheds only ~13% a tick.
    p.botPathGateTooFast += 1;
    global.botFollowerSteerBraking = true;
}
else
{
    // Split for the diagnostic only.
    if (along < 0)
        p.botPathGateBackwards += 1;
    else
        p.botPathGateShort += 1;

    // Moving away from the jump, or too slow for this arc: back up. But a bot
    // still SHORT OF the takeoff column and still gaining needs the rest of
    // the run it is on - once a run-up has already been spent.
    shortOfTakeoff = (takeoff - column) * jumpDir > 0;

    if (along > 0 and shortOfTakeoff and p.botPathRunupsStarted > 0)
    {
        global.botFollowerSteerTargetColumn = takeoff;
    }
    else
    {
        // The run-up follows WALK edges through the graph, not the node's own
        // columns (a one-column top step clamps back to where the bot stands).
        if (p.botPathRunupAt < 0)
        {
            p.botPathRunupAt = botJumpRunupColumn(from, takeoff, jumpDir, BOT_RUNUP_CELLS,
                qTeam, qIntel, qSetup, qDJ, qRJ, qSJ);

            p.botPathRunupsStarted += 1;
        }

        global.botFollowerSteerTargetColumn = p.botPathRunupAt;
    }
}

// The escape hatch: a gate that can refuse can refuse FOR EVER. Jump on
// whatever it has instead - except a rocket arc with no rocket, which is taken
// away rather than flown as a 57px hop.
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

    // WITH the rocket: the hatch used to leave a ready-launcher rocket arc
    // with no rocket.
    botFollowerLaunch(p, isRocket, rocketAim);
}

return 0;
