// botFollowerStep(player, char, team, hasIntel, setupGatesClosed,
//                 canDoubleJump, canRocketJump, canStickyJump)
// PathFollower.Step: advances the route one tick. Returns movement keys
// (LEFT/RIGHT/JUMP/DOWN). `char` must be live; the six arguments are the live
// NavQuery. Launch requests reset each tick; the sticky countdown persists.
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

// 0.5px: wall contact jitters at sub-pixel scale.
moved = abs(px - p.botPathLastX) > 0.5 or abs(py - p.botPathLastY) > 0.5;
p.botPathLastX = px;
p.botPathLastY = py;

// Event-driven re-plans set ReplanAt to 0.
if (global.botTick >= p.botPathReplanAt)
    botFollowerPlan(p, px, py, qTeam, qIntel, qSetup, qDJ, qRJ, qSJ);

route = p.botPathPath;
size = ds_list_size(route);
if (size == 0)
    return 0;

// Grounded only: NodeFromWorld resolves a landing early in the air.
here = -1;
if (onGround)
    here = navGraphNodeFromWorld(px, py);
found = false;

if (here >= 0)
{
    // Forward only, so a node visited twice cannot loop.
    for (i = p.botPathPathAt; i < size; i += 1)
    {
        if (ds_list_find_value(route, i) == here)
        {
            p.botPathPathAt = i;
            found = true;
            break;
        }
    }

    // A run-up walks off-route backwards; counts as on route, PathAt unchanged.
    if (!found and p.botPathRunupAt >= 0)
        found = true;
}

// Grounded on an off-route node: re-plan now. On no node: count. Airborne:
// neither.
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
