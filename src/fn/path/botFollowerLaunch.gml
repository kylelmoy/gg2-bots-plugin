// botFollowerLaunch(player, rocket, aim) - PathFollower.Launch: commits to the
// arc - asks for the press (global.botFollowerSteerWantJump) and resets the
// per-arc state.
//
// `rocket` asks for the rocket as well, and is a parameter rather than the
// caller's business precisely because it used to be: of two launch sites only
// one fired, and the other flew rocket arcs as ordinary jumps. `aim` is the
// rocket's aim (C# default RocketAimDegrees; callers pass it explicitly). The
// aim itself is applied by botFollowerApplyLaunch after the combat half.
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

// The arc was flown, so whatever it took to get off the ground is spent.
p.botPathRunupsStarted = 0;
p.botPathRunupsEdgeFrom = -1;
p.botPathRunupsEdgeTo = -1;
