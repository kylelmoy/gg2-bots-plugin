// botJumpReach(char, needVx, flightTicks, v0) - JumpModel.Reach
// (botJumpReach.gml): how far along an arc this character would actually get,
// in world pixels, leaving the takeoff column carrying v0 along the jump and
// flying it the way botFollowerFollowEdge's tracker does.
//
// The generator proved the arc as a CONSTANT horizontal velocity from tick
// zero; a GG2 character accelerates, and starts from whatever it carries. The
// tracker catches up only out of the surplus between the arc's speed and the
// class's ceiling. 3,310 of 62,069 jump edges are unflyable by a heavy from
// its run-up, and 91.9% need no takeoff speed at all - which is why the gate
// asks this rather than demanding the arc's full speed.
//
// The motion law is Character's Begin Step in its own order: the run key adds
// first and only while under basemaxspeed, friction divides afterwards, the
// snap to rest applies only with nothing held. The control factor is
// CharacterPhysics.ControlAndFriction's - from moveStatus, not onground - so
// the same value applies in the air.
//
// The tracker replayed here is the follower's own; change one, change both.
// NOT monotonic in v0 (arriving ahead of schedule makes the tracker brake):
// never bisect this for a threshold.
var char, needVx, flightTicks, v0, control, acceleration, maxSpeed, frictionNow;
var total, speedNow, travelled, ticks, air, want, press;
char = argument0;
needVx = argument1;
flightTicks = argument2;
v0 = argument3;

// CharacterPhysics.ControlAndFriction's control half (Begin Step.xml's
// switch). Humiliation costs 0.2 and intel 0.1 and they do not add.
switch (char.moveStatus)
{
    case 1: control = 0.65; break;              // rocketing myself
    case 2: control = 0.45; break;              // rocketed by an enemy
    case 3: control = 0.35; break;              // airblast
    case 4: control = char.baseControl; break;  // rocketed by a team-mate
    default:
        if (char.player.humiliated)
            control = char.baseControl - 0.2;
        else if (char.intel)
            control = char.baseControl - 0.1;
        else
            control = char.baseControl;
        break;
}

acceleration = char.runPower * control;
maxSpeed = char.basemaxspeed;
frictionNow = char.baseFriction;

// Character's own Create warns that baseFriction may be neither 0 nor 1; a
// caller handing over something that is not a character gets a bad answer
// rather than a division.
if (frictionNow <= 0)
    return 0;

total = needVx * flightTicks;
speedNow = v0;
travelled = 0;

// GM8's round - half to even, which is what Gml.Round reproduces.
ticks = max(1, round(flightTicks));

for (air = 1; air <= ticks; air += 1)
{
    want = min(total, needVx * air);

    press = 0;
    if (travelled < want - 1)
        press = 1;
    else if (travelled > want + 1)
        press = -1;

    if (press > 0 and speedNow <= maxSpeed)
        speedNow += acceleration;
    else if (press < 0 and speedNow >= -maxSpeed)
        speedNow -= acceleration;

    speedNow /= frictionNow;

    // The "ice skating" snap, only with nothing held.
    if (abs(speedNow) < BOT_REST_SPEED and press == 0)
        speedNow = 0;

    travelled += speedNow;
}

return travelled;
