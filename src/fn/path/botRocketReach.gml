// botRocketReach(char, needVx, flightTicks, v0) - RocketModel.Reach: px along a
// rocket-jump arc from takeoff speed v0, under moveStatus 1 (NAV_RJ_CONTROL,
// NAV_RJ_FRICTION) with a speed-gated tracker. Must match gg2-nav-gen's
// follow.js. Not monotonic in v0; never bisect.
var char, needVx, flightTicks, v0, acceleration, maxSpeed, frictionNow;
var total, speedNow, travelled, ticks, air, want, press;
char = argument0;
needVx = argument1;
flightTicks = argument2;
v0 = argument3;

acceleration = char.runPower * NAV_RJ_CONTROL;
maxSpeed = char.basemaxspeed;

frictionNow = NAV_RJ_FRICTION;

if (frictionNow <= 0)
    return 0;

total = needVx * flightTicks;
speedNow = v0;
travelled = 0;
ticks = max(1, round(flightTicks));

for (air = 1; air <= ticks; air += 1)
{
    want = min(total, needVx * air);

    // Position picks the direction; speed gates the press (converges with no
    // friction). botJumpReach has no gate and must not grow one.
    press = 0;

    if (travelled < want - 1)
    {
        if (speedNow < needVx)
            press = 1;
    }
    else if (travelled > want + 1)
    {
        if (speedNow > needVx)
            press = -1;
    }

    if (press > 0 and speedNow <= maxSpeed)
        speedNow += acceleration;
    else if (press < 0 and speedNow >= -maxSpeed)
        speedNow -= acceleration;

    speedNow /= frictionNow;

    if (abs(speedNow) < BOT_REST_SPEED and press == 0)
        speedNow = 0;

    travelled += speedNow;
}

return travelled;
