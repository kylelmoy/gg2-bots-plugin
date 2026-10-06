// botAllyFind(player, range, skipFollowers): BotAlly.Find - botFindAlly.gml.
// The team-mate a medic should beam (or follow): a Player instance, or noone
// (BotAlly.None). Scored, lowest best:
//   score = 1000 * hp / maxHp + distance - maxHp
//           - BOT_ALLY_HUMAN_PATIENT if the patient is a person (!botIsBot)
//           + BOT_ALLY_FULL_HEALTH   if at full health (a partition)
// skipFollowers drops every candidate of a following CLASS (two medics who
// follow each other deadlock); the beam passes false. Never a cloaked spy -
// the beam would be drawn straight at it. Line of sight is
// collision_line against Obstacle (what Healing uses), folded into the scan:
// the best candidate that HAS a line. Ties go to the earlier instance.
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
