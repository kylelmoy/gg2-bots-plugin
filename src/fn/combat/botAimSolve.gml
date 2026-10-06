// botAimSolve(char, targetX, targetY, targetVx, targetVy, leadMode, floorY):
// BotAim.Solve - botAimSolve.gml. Where to point (degrees, GM8 convention) to
// hit a target moving at (targetVx, targetVy), for the weapon model
// botAimBallistics gives. floorY is the floor under the target
// (botAimFloorUnder), BOT_AIM_NO_FLOOR when unknown.
//   speed 0 (hitscan / beam)  straight at it
//   BOT_LEAD_NONE             through the solver, gravity only
//   BOT_LEAD_LINEAR           one pass from the current distance
//   BOT_LEAD_FULL             the iterated intercept with the fall clamped
var c, tx, ty, tvx, tvy, lead, spd, grav, drift, t, dir;
c = argument0;
tx = argument1;
ty = argument2;
tvx = argument3;
tvy = argument4;
lead = argument5;

spd = botAimBallistics(c);
grav = global.botRetGravity;
drift = global.botRetDrift;

if (spd <= 0)
    return point_direction(c.x, c.y, tx, ty);

if (lead == BOT_LEAD_NONE)
{
    dir = botAimLead(c.x, c.y, tx, ty, 0, 0, spd, grav, drift, ty);
    return dir;
}

if (lead == BOT_LEAD_LINEAR)
{
    t = min(max(point_distance(c.x, c.y, tx, ty) / spd, 1), BOT_AIM_MAX_TICKS);
    dir = botAimLead(c.x, c.y, tx + tvx * t, ty + tvy * t, 0, 0, spd, grav, drift, ty + tvy * t);
    return dir;
}

dir = botAimLead(c.x, c.y, tx, ty, tvx, tvy, spd, grav, drift, argument6);
return dir;
