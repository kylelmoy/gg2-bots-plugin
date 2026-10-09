// botJumpReach(char, needVx, flightTicks, v0) - JumpModel.Reach: px along an
// arc the character covers from takeoff speed v0, replaying the follower's
// tracker under Begin Step's motion law. Must match the tracker.
// Not monotonic in v0; never bisect.
var char, needVx, flightTicks, v0, control, acceleration, maxSpeed, frictionNow;
var total, speedNow, travelled, ticks, air, want, press;
char = argument0;
needVx = argument1;
flightTicks = argument2;
v0 = argument3;

// ControlAndFriction's control half; humiliation and intel do not stack.
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

if (frictionNow <= 0)
    return 0;

total = needVx * flightTicks;
speedNow = v0;
travelled = 0;

// round is half-to-even.
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

    // Snap to rest only with nothing held.
    if (abs(speedNow) < BOT_REST_SPEED and press == 0)
        speedNow = 0;

    travelled += speedNow;
}

return travelled;
