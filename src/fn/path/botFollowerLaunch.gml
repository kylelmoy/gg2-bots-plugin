// botFollowerLaunch(player, rocket, aim) - PathFollower.Launch: requests the
// jump (and rocket, at aim degrees, if `rocket`) and resets per-arc state.
// aim has no default; botFollowerApplyLaunch applies it.
var p, rocket, aim;
p = argument0;
rocket = argument1;
aim = argument2;

global.botFollowerSteerWantJump = true;

if (rocket)
{
    global.botFollowerSteerRocketFire = true;
    p.botPathRocketAim = aim;
    p.botPathRocketJumps += 1;
}

p.botPathAirTicks = 0;
p.botPathTakeoffTicks = 0;
p.botPathRunupAt = -1;
p.botPathRejumped = false;

p.botPathRunupsStarted = 0;
p.botPathRunupsEdgeFrom = -1;
p.botPathRunupsEdgeTo = -1;
