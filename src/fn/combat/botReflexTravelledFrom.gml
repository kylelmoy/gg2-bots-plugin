// botReflexTravelledFrom(projectile): BotReflex.TravelledFrom - distance flown
// from the shooter: a Rocket's lastknownx/y, else the owner's live character
// (huge if none).
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
