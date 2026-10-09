// botHandoverDistanceToNearestEnemy(player, char, humansOnly):
// Handover.DistanceToNearestEnemy - pixels to the nearest live enemy, or -1
// for none (C#'s infinity). humansOnly skips bot enemies.
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
