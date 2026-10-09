// botTargetingUnderFire(player): BotTargeting.UnderFire - hit by someone else
// within BOT_UNDER_FIRE_TICKS (timeUnscathed, 30 Hz). A rocket jump does not
// count; afterburn does.
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
