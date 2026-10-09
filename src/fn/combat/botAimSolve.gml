// botAimSolve(char, targetX, targetY, targetVx, targetVy, leadMode, floorY):
// BotAim.Solve - aim direction in degrees. floorY: BOT_AIM_NO_FLOOR if unknown.
// Speed 0 aims straight; BOT_LEAD_NONE gravity only; LINEAR one pass; FULL
// iterated.
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
