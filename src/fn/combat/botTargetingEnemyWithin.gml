// botTargetingEnemyWithin(player, range): BotTargeting.EnemyWithin - any live,
// visible enemy within range (botVisibilityCanSee inlined).
var p, me, myTeam, range, mx, my, mxs, found, vis;
p = argument0;
range = argument1;
me = p.object;
if (me == -1)
    return false;
myTeam = p.team;
mx = me.x;
my = me.y;
mxs = me.image_xscale;
found = false;
with (Character)
{
    if (id == me)
        continue;
    if (player.team == myTeam)
        continue;
    if (hp <= 0)
        continue;
    vis = true;
    if (cloak)
    {
        vis = false;
        if (stabbing)
            vis = (sign(x - mx) != -sign(mxs));
    }
    if (!vis)
        continue;
    if (point_distance(x, y, mx, my) <= range)
    {
        found = true;
        break;
    }
}
return found;
