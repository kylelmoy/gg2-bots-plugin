// botReflexIncomingProjectile(player, minTravel, reflexTicks, missChance):
// BotReflex.IncomingProjectile - botIncomingProjectile.gml. Is a reflectable
// enemy projectile (Rocket, Flare, Mine - Flamethrower User Event 2's set)
// somewhere the airblast can reach, having already flown minTravel px.
// Both the projectile's position and its position one tick on are tested
// (botReflexInBlastBeam, inlined), either will do. The radius test is only the
// C#'s cheap pre-filter (reach + a tick of travel); the beam decides.
// reflexTicks/missChance 0 is a perfect reflex.
var p, me, myTeam, minTravel, rt, mc, mx, my, fx, fy, sx, sy, found, pass;
var travelled, seen, dx, dy, fwd, hit, obj;
p = argument0;
minTravel = argument1;
rt = argument2;
mc = argument3;
me = p.object;
if (me == -1)
    return false;
myTeam = p.team;
mx = me.x;
my = me.y;
fx = lengthdir_x(1, me.aimDirection);
fy = lengthdir_y(1, me.aimDirection);
sx = lengthdir_x(1, me.aimDirection + 90);
sy = lengthdir_y(1, me.aimDirection + 90);
found = false;

for (pass = 0; pass < 3; pass += 1)
{
    if (found)
        break;
    // with() over one object per pass; the body is the same for all three.
    if (pass == 0)
        obj = Rocket;
    else if (pass == 1)
        obj = Mine;
    else
        obj = Flare;
    with (obj)
    {
        if (team == myTeam)
            continue;
        if (point_distance(x, y, mx, my) > BOT_AIRBLAST_REACH + BOT_DODGE_RANGE)
            continue;
        travelled = botReflexTravelledFrom(id);
        if (travelled < minTravel)
            continue;
        seen = botReflexNoticed(id, p, rt, mc);
        if (!seen)
            continue;
        hit = false;
        dx = x - mx;
        dy = y - my;
        fwd = dx * fx + dy * fy;
        if (fwd >= BOT_AIRBLAST_NEAR and fwd <= BOT_AIRBLAST_REACH)
            hit = (abs(dx * sx + dy * sy) <= BOT_AIRBLAST_HALFW);
        if (!hit)
        {
            dx = x + hspeed - mx;
            dy = y + vspeed - my;
            fwd = dx * fx + dy * fy;
            if (fwd >= BOT_AIRBLAST_NEAR and fwd <= BOT_AIRBLAST_REACH)
                hit = (abs(dx * sx + dy * sy) <= BOT_AIRBLAST_HALFW);
        }
        if (hit)
        {
            found = true;
            break;
        }
    }
}
return found;
