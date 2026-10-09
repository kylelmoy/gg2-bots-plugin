// botArcClear(char, aimDegrees, speed, gravity, targetX, targetY) -
// BotArc.Clear: whether a shot reaches the target unobstructed, sampled along
// the parabola. speed <= 0 answers true. Departs: one
// collision_line_bulletblocking per segment instead of pre-filtering rects
// (same answer).
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

vx = lengthdir_x(spd, aimDir);
vy = lengthdir_y(spd, aimDir);

// Near-vertical: straight-line flight estimate.
if (abs(vx) > 0.01)
    flight = (tx - sx) / vx;
else
    flight = point_distance(sx, sy, tx, ty) / spd;

flight = min(max(flight, 1), BOT_AIM_MAX_TICKS);

bx = sx;
by = sy;

for (i = 1; i <= BOT_ARC_SAMPLES; i += 1)
{
    if (i == BOT_ARC_SAMPLES)
    {
        // Last sample is the target itself, not the parabola's end.
        ax = tx;
        ay = ty;
    }
    else
    {
        t = flight * i / BOT_ARC_SAMPLES;

        // Exact: gravity is added to vspeed before the move.
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
