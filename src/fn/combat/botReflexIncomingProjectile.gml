// botReflexIncomingProjectile(player, minTravel, reflexTicks, missChance):
// BotReflex.IncomingProjectile - is a noticed enemy Rocket/Mine/Flare that has
// flown minTravel px in the airblast beam, now or one tick on. The radius test
// is a pre-filter.
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
    // One object per pass.
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
