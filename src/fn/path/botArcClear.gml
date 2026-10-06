// botArcClear(char, aimDegrees, speed, gravity, targetX, targetY) - BotArc.Clear
// (botArcClear.gml): whether a shot at aimDegrees reaches (targetX, targetY)
// unobstructed, sampled along the PARABOLA rather than the straight line.
//
// Nothing else in the bot layer checks a projectile's arc, while the aim
// solver aims ABOVE the target to compensate for drop (~178px of sag at 500px
// for a Minegun round) - indoors, "sometimes shooting at the ceiling".
// Withholding rather than re-solving is deliberate: a flatter solution means
// closing the distance, a positioning decision BotGoalSpot owns.
//
// `speed` must be positive; zero answers true rather than dividing.
//
// The C# lays the samples out first and filters the map's rects once for the
// whole parabola; that is a cost optimisation with an identical answer. Here
// each segment is one collision_line_bulletblocking, which is the game's own
// bullet-blocking set (CollisionFilter.ForBullet) and safe from anywhere.
var char, aimDir, spd, grav, tx, ty, sx, sy, vx, vy, flight, i, t, ax, ay, bx, by, blocked;
char = argument0;
aimDir = argument1;
spd = argument2;
grav = argument3;
tx = argument4;
ty = argument5;

if (spd <= 0)
    return true;

sx = char.x;
sy = char.y;

// lengthdir_*: GM8's y axis points down and these already account for it.
vx = lengthdir_x(spd, aimDir);
vy = lengthdir_y(spd, aimDir);

// Very nearly vertical: the horizontal offset says nothing about the flight
// time, so fall back to the straight-line estimate.
if (abs(vx) > 0.01)
    flight = (tx - sx) / vx;
else
    flight = point_distance(sx, sy, tx, ty) / spd;

// The lower bound keeps a target on the shooter from collapsing every sample
// onto the muzzle; the upper is a cost bound.
flight = min(max(flight, 1), BOT_AIM_MAX_TICKS);

bx = sx;
by = sy;

for (i = 1; i <= BOT_ARC_SAMPLES; i += 1)
{
    if (i == BOT_ARC_SAMPLES)
    {
        // The last sample is the TARGET itself, not the parabola's endpoint,
        // so a tick of flight-time error cannot put it into the floor the
        // target stands on.
        ax = tx;
        ay = ty;
    }
    else
    {
        t = flight * i / BOT_ARC_SAMPLES;

        // t * (t + 1) / 2 is EXACT: gravity is added to vspeed before the move.
        ax = sx + vx * t;
        ay = sy + vy * t + grav * t * (t + 1) / 2;
    }

    blocked = collision_line_bulletblocking(bx, by, ax, ay);
    if (blocked)
        return false;

    bx = ax;
    by = ay;
}

return true;
