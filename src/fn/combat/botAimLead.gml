// botAimLead(sourceX, sourceY, targetX, targetY, targetVx, targetVy, speed,
//            gravity, drift, floorY): BotAim.Lead - botAimLead.gml.
// The iterated intercept: guess the flight time from the straight distance,
// work out where the target will be then, re-measure; BOT_AIM_ITERATIONS + 1
// evaluations, the aim point from the last. The projectile's own drop is
// gravity * t * (t + 1) / 2 (discrete ticks) and is SUBTRACTED - aiming higher
// compensates for a shot that drops. t is clamped to [1, BOT_AIM_MAX_TICKS].
// Returns a direction in degrees. botAimFallPredict is inlined in the loop
// (the same formula) so the solve costs no calls.
var sx, sy, tx, ty, tvx, tvy, spd, grav, drift, tfloor, t, i, ax, ay, clampTicks, fy;
sx = argument0;
sy = argument1;
tx = argument2;
ty = argument3;
tvx = argument4;
tvy = argument5;
spd = argument6;
grav = argument7;
drift = argument8;
tfloor = argument9;

clampTicks = 0;
if (tvy < NAV_JUMP_TERM_VY)
    clampTicks = (NAV_JUMP_TERM_VY - tvy) / NAV_JUMP_GRAVITY;

t = point_distance(sx, sy, tx, ty) / spd;
ax = tx;
ay = ty;
for (i = 0; i <= BOT_AIM_ITERATIONS; i += 1)
{
    t = min(max(t, 1), BOT_AIM_MAX_TICKS);
    ax = tx + (tvx - drift) * t;
    if (t <= clampTicks)
        fy = ty + tvy * t + NAV_JUMP_GRAVITY * t * t / 2;
    else
        fy = ty + tvy * clampTicks + NAV_JUMP_GRAVITY * clampTicks * clampTicks / 2
             + NAV_JUMP_TERM_VY * (t - clampTicks);
    fy = min(fy, tfloor);
    ay = fy - grav * t * (t + 1) / 2;
    t = point_distance(sx, sy, ax, ay) / spd;
}
return point_direction(sx, sy, ax, ay);
