// botReflexRocketDodge(player, reflexTicks, missChance): BotReflex.RocketDodge
// - would jumping now dodge an enemy rocket that hits it standing. Grounded
// callers only. Rocket flies straight; bot keeps hspeed, standing or jumping
// (rise = NAV_JUMP_V0 t - NAV_JUMP_GRAVITY t^2 / 2). No splash.
var p, me, myTeam, rt, mc, mx, my, mvx, halfW, found, seen, t;
var hitStanding, hitJumping, rocketX, rocketY, bodyX, rise, jumpY;
p = argument0;
rt = argument1;
mc = argument2;
me = p.object;
if (me == -1)
    return false;
myTeam = p.team;
mx = me.x;
my = me.y;
mvx = me.hspeed;
halfW = BOT_BODY_HALFW + BOT_ROCKET_RADIUS;
found = false;

with (Rocket)
{
    if (team == myTeam)
        continue;
    if (point_distance(x, y, mx, my) > BOT_DODGE_RANGE)
        continue;
    seen = botReflexNoticed(id, p, rt, mc);
    if (!seen)
        continue;
    hitStanding = false;
    hitJumping = false;
    for (t = 1; t <= BOT_DODGE_TICKS; t += 1)
    {
        rocketX = x + hspeed * t;
        rocketY = y + vspeed * t;
        bodyX = mx + mvx * t;
        if (abs(rocketX - bodyX) > halfW)
            continue;
        if (rocketY >= my - BOT_BODY_UP - BOT_ROCKET_RADIUS
            and rocketY <= my + BOT_BODY_DOWN + BOT_ROCKET_RADIUS)
            hitStanding = true;
        rise = NAV_JUMP_V0 * t - NAV_JUMP_GRAVITY * t * t / 2;
        jumpY = my - rise;
        if (rocketY >= jumpY - BOT_BODY_UP - BOT_ROCKET_RADIUS
            and rocketY <= jumpY + BOT_BODY_DOWN + BOT_ROCKET_RADIUS)
            hitJumping = true;
        // Verdict cannot change.
        if (hitStanding and hitJumping)
            break;
    }
    if (hitStanding and !hitJumping)
    {
        found = true;
        break;
    }
}
return found;
