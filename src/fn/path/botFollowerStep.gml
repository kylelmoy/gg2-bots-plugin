// botFollowerStep(player, char, team, hasIntel, setupGatesClosed,
//                 canDoubleJump, canRocketJump, canStickyJump)
// PathFollower.Step (botPathKeys.gml): advances one bot's route by a tick and
// returns the movement keys - LEFT / RIGHT / JUMP / DOWN, never an attack or a
// special. The weapon is char.currentWeapon. `char` must be the live
// Character (player.object != -1); the six arguments are the LIVE NavQuery.
//
// Surfacer's surface navigator plus Quake III's think loop:
//  1. note whether the bot moved at all since last tick (the stuck detector's
//     only input);
//  2. plan, if the re-plan timer is up;
//  3. find which node the bot is standing on and advance along the route to
//     it; failing to find itself on the route at all is an interruption;
//  4. steer along the current edge according to what kind of move it is;
//  5. if keys were pressed and nothing moved for BOT_STUCK_TICKS, give up on
//     this edge: blacklist it and re-plan.
//
// The four launch requests are cleared up front, so a tick that does not reach
// the takeoff gate cannot leave last tick's request standing for
// botFollowerApplyLaunch. The sticky COUNTDOWN is not cleared: it has to
// survive the ticks between placing the mine and jumping on it.
var p, char, qTeam, qIntel, qSetup, qDJ, qRJ, qSJ;
var px, py, onGround, moved, size, here, found, i, route;
p = argument0;
char = argument1;
qTeam = argument2;
qIntel = argument3;
qSetup = argument4;
qDJ = argument5;
qRJ = argument6;
qSJ = argument7;

p.botPathFlyingEdge = false;
p.botPathRocketFire = false;
p.botPathMineFire = false;
p.botPathMineDetonate = false;

// ScriptedBot: `_graph is null ? PlayerKeys.None : _follower.Step(...)`.
if (!global.botNavReady)
    return 0;

if (!p.botPathHasGoal)
    return 0;

px = char.x;
py = char.y;
onGround = char.onground;

// Half a pixel, not zero: good_move_contact_solid works at 1/8 pixel
// precision, so a bot grinding against a wall jitters without going anywhere.
moved = abs(px - p.botPathLastX) > 0.5 or abs(py - p.botPathLastY) > 0.5;
p.botPathLastX = px;
p.botPathLastY = py;

// Planning is on the timer even when it FAILS. Event-driven re-plans set
// ReplanAt to 0 rather than calling in here.
if (global.botTick >= p.botPathReplanAt)
    botFollowerPlan(p, px, py, qTeam, qIntel, qSetup, qDJ, qRJ, qSJ);

route = p.botPathPath;
size = ds_list_size(route);
if (size == 0)
    return 0;

// Only while standing on something. NodeFromWorld tolerates being a couple of
// cells off a surface, so an arc passing over its own landing resolves to that
// node ~15px early - advancing there hands the follower the NEXT edge while
// the bot is still in the air.
here = -1;
if (onGround)
    here = navGraphNodeFromWorld(px, py);
found = false;

if (here >= 0)
{
    // Forward only: looking backwards would let a long surface the route
    // touches twice pull it into a loop.
    for (i = p.botPathPathAt; i < size; i += 1)
    {
        if (ds_list_find_value(route, i) == here)
        {
            p.botPathPathAt = i;
            found = true;
            break;
        }
    }

    // A run-up deliberately walks BACKWARDS along the route (often over floor
    // the route never mentions), which the forward search cannot see. PathAt
    // is NOT moved: the edge being prepared for stays the current one. What
    // bounds this is the takeoff budget, not this test.
    if (!found and p.botPathRunupAt >= 0)
        found = true;
}

// Standing on a surface the route does not mention is a finished move that
// went somewhere else: re-plan at once. Not knowing where we are at all gets
// the timer - and an airborne bot touches neither counter.
if (found)
{
    p.botPathOffPathTicks = 0;
}
else if (onGround)
{
    if (here >= 0)
        return botFollowerOffRoute(p, px, py, qTeam, qIntel, qSetup, qDJ, qRJ, qSJ);

    p.botPathOffPathTicks += 1;
}

if (p.botPathOffPathTicks > BOT_OFFPATH_TICKS)
{
    botFollowerPlan(p, px, py, qTeam, qIntel, qSetup, qDJ, qRJ, qSJ);
    return 0;
}

if (p.botPathPathAt >= size - 1)
    return botFollowerWalkToGoal(p, px, py, char.hspeed, onGround, moved, qTeam, qIntel, qSetup, qDJ, qRJ, qSJ);

return botFollowerFollowEdge(p, char, moved, qTeam, qIntel, qSetup, qDJ, qRJ, qSJ);
