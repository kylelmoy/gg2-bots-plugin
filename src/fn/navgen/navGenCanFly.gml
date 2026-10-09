// navGenCanFly(from, vx, ticks, bx0, bx1): the fans' CanFly veto - can a bot
// leaving column `from` of node global.navGenCurI toward global.navGenCurDir
// actually cover the ground to the landing run [bx0, bx1]? Its speed at
// takeoff is what the node's run-up buys (cached per takeoff column for the
// node-side) capped at the arc's own speed + BOT_JUMP_VTOL, then the flight is
// integrated tick by tick under the model's air law (NavCharacter.FlyDistance,
// or FlyDistanceRocket for the rocket jump).
var from, needVx, ticks, bx0, bx1, need, cols, cache, v0, total, v, xx, n, air, want, press, acc, mx, fr, rocket;
from = argument0;
needVx = argument1;
ticks = argument2;
bx0 = argument3;
bx1 = argument4;
if (bx0 > from)
    need = bx0 - from;
else if (bx1 < from)
    need = from - bx1;
else
    need = 0;
if (need == 0)
    return true;

cache = global.navGenRunupCache;
if (ds_map_exists(cache, from))
    cols = ds_map_find_value(cache, from);
else
{
    cols = navGenRunupCols(global.navGenCurI, from, global.navGenCurDir);
    ds_map_add(cache, from, cols);
}

acc = global.navGenAirAccel;
mx = global.navGenAirMax;
fr = global.navGenAirFriction;
rocket = global.navGenRocketLaw;
v0 = min(global.navGenRunupV[cols], min(needVx + BOT_JUMP_VTOL, mx));
total = needVx * ticks;
v = v0;
xx = 0;
n = max(1, floor(ticks + 0.5));
for (air = 1; air <= n; air += 1)
{
    want = min(total, needVx * air);
    press = 0;
    if (xx < want - 1)
    {
        if (!rocket || v < needVx)
            press = 1;
    }
    else if (xx > want + 1)
    {
        if (!rocket || v > needVx)
            press = -1;
    }
    if (press > 0)
    {
        if (v <= mx)
            v += acc;
    }
    else if (press < 0)
    {
        if (v >= -mx)
            v -= acc;
    }
    v /= fr;
    if (abs(v) < NAV_GEN_REST_SPEED && press == 0)
        v = 0;
    xx += v;
}
return (xx + BOT_JUMP_REACH_TOL >= need * NAV_CELL_SIZE);
