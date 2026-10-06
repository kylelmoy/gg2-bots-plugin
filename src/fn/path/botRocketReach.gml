// botRocketReach(char, needVx, flightTicks, v0) - RocketModel.Reach
// (botRocketReach.gml): how far along a ROCKET-JUMP arc the character gets,
// leaving the takeoff column carrying v0 along the jump.
//
// botJumpReach answers this for every other kind and the two must not be
// merged: they differ in BOTH terms of the motion law. moveStatus 1
// ("rocketing/mining myself") is control 0.65 and friction 1 - and friction 1
// means horizontal speed never bleeds for the whole flight. So a slow takeoff
// catches up faster and a hot one cannot coast down; the ordinary model would
// be wrong in both directions at once.
//
// The control factor is NAV_RJ_CONTROL, not read off the character: at the
// gate the bot is still on the ground at moveStatus 0. basemaxspeed IS read
// live: Begin Step's cap test reads the stored value. gg2-nav-gen's follow.js
// runs the same law on the generator side; if one moves, move both.
//
// NOT monotonic in v0; never bisect it.
var char, needVx, flightTicks, v0, acceleration, maxSpeed, frictionNow;
var total, speedNow, travelled, ticks, air, want, press;
char = argument0;
needVx = argument1;
flightTicks = argument2;
v0 = argument3;

acceleration = char.runPower * NAV_RJ_CONTROL;
maxSpeed = char.basemaxspeed;

// NAV_RJ_FRICTION is 1 and the divide below is written out, so that a change
// to the constant changes this rather than being a silent no-op.
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

    // The speed gate, which is what makes this law converge with no friction
    // under it: position decides whether to press, speed whether pressing can
    // help. botJumpReach has no such gate and must not grow one.
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
