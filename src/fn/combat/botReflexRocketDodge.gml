// botReflexRocketDodge(player, reflexTicks, missChance): BotReflex.RocketDodge
// - botRocketDodge.gml. Would jumping right now take this bot out of the path
// of an enemy rocket that is otherwise going to hit it. Grounded callers only.
// Models the arc rather than a radius: the rocket is a straight line at its
// current hspeed/vspeed, the bot carries its hspeed and either stands or flies
// the standing jump rise(t) = NAV_JUMP_V0 t - NAV_JUMP_GRAVITY t^2 / 2. The
// verdict is "standing is hit at some tick AND jumping is hit at none" - never
// jump at a rocket that misses anyway, never jump into one passing overhead.
// Splash is deliberately not modelled.
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
        // Nothing later in the walk can change the verdict for this rocket.
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
