// botHandoverDistanceToNearestEnemy(player, char, humansOnly):
// Handover.DistanceToNearestEnemy - straight-line pixels to the nearest live
// enemy character, or -1 when there is none (the C#'s infinity: "nobody to
// fight" must fail the range test).
//
// Under humansOnly (EngageOpponents.HumansOnly) a bot enemy does not count,
// and is skipped rather than ending the search: the nearest enemy may be a bot
// with a human just behind it. Enemy is by team (Character.team, its player's
// team when it spawned) and alive is "has a Character".
var pl, ch, hum, cx, cy, myteam, best, d, skip;
pl = argument0;
ch = argument1;
hum = argument2;
cx = ch.x;
cy = ch.y;
myteam = pl.team;
best = -1;
with (Character)
{
    if (id != ch)
    {
        if (team != myteam)
        {
            skip = false;
            if (hum)
                skip = player.botIsBot;
            if (!skip)
            {
                d = sqr(x - cx) + sqr(y - cy);
                if (best < 0 or d < best)
                    best = d;
            }
        }
    }
}
if (best < 0)
    return -1;
return sqrt(best);
