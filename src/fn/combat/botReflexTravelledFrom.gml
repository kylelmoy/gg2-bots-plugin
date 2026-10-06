// botReflexTravelledFrom(projectile): BotReflex.TravelledFrom - how far this
// projectile has flown from whoever fired it.
// A Rocket carries the number: move_all_bullets refreshes lastknownx/y from
// its owner every step (and they freeze where a dead shooter fell), so it is
// measured to those. A Flare or Mine is measured to its ownerPlayer's live
// character; one whose owner has gone or died has travelled far enough.
var pr, own, c;
pr = argument0;
if (pr.object_index == Rocket)
    return point_distance(pr.x, pr.y, pr.lastknownx, pr.lastknowny);
own = pr.ownerPlayer;
if (own == -1 or own == noone)
    return 1000000000;
if (!instance_exists(own))
    return 1000000000;
c = own.object;
if (c == -1)
    return 1000000000;
return point_distance(pr.x, pr.y, c.x, c.y);
