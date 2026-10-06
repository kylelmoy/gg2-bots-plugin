// botTargetingUnderFire(player): BotTargeting.UnderFire - has this bot been
// hit recently by something that was not itself.
// Read off the character's own fields: timeUnscathed (reset by every damage
// path, counted up in Character Step in 30 Hz units) and lastDamageDealer (a
// Player, noone when Alarm 3 has cleared it). A rocket jump names the jumper
// as its own dealer, so it is not being under fire; afterburn names whoever
// lit the fire, which is.
var p, c;
p = argument0;
c = p.object;
if (c == -1)
    return false;
if (c.timeUnscathed > BOT_UNDER_FIRE_TICKS)
    return false;
if (c.lastDamageDealer == noone)
    return false;
return (c.lastDamageDealer != p);
