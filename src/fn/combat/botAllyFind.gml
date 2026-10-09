// botAllyFind(player, range, skipFollowers): BotAlly.Find - the team-mate a
// medic beams/follows: a Player, or noone. Lowest score wins:
//   1000 * hp / maxHp + distance - maxHp, - BOT_ALLY_HUMAN_PATIENT if human,
//   + BOT_ALLY_FULL_HEALTH if full. skipFollowers drops following classes.
// Never a cloaked spy; needs a clear line against Obstacle. Ties: earlier
// instance.
var p, me, myTeam, mx, my, range, skip, best, bestScore, dist, sc, mhp, follows, blocked;
p = argument0;
range = argument1;
skip = argument2;
best = noone;
me = p.object;
if (me == -1)
    return noone;
myTeam = p.team;
mx = me.x;
my = me.y;
bestScore = 1000000000;
with (Character)
{
    if (id == me)
        continue;
    if (player.team != myTeam)
        continue;
    if (hp <= 0)
        continue;
    if (skip)
    {
        follows = botClassProfileFollows(player.class);
        if (follows)
            continue;
    }
    if (cloak)
        continue;
    dist = point_distance(x, y, mx, my);
    if (dist > range)
        continue;
    mhp = maxHp;
    sc = 1000 * hp / mhp + dist - mhp;
    if (!player.botIsBot)
        sc -= BOT_ALLY_HUMAN_PATIENT;
    if (!(hp < mhp))
        sc += BOT_ALLY_FULL_HEALTH;
    if (sc >= bestScore)
        continue;
    blocked = collision_line(mx, my, x, y, Obstacle, true, true);
    if (blocked >= 0)
        continue;
    best = player;
    bestScore = sc;
}
return best;
