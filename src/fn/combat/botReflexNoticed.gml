// botReflexNoticed(projectile, player, reflexTicks, missChance):
// BotReflex.Noticed - has this bot seen this projectile coming; the
// difficulty's gate on both reflexes.
// The reaction time is a DISTANCE: the projectile must have flown
// reflexTicks ticks' worth of its own speed. The miss is decided once per
// projectile and bot by a hash (botReflexRoll), never re-rolled per tick.
var pr, travelled, roll;
pr = argument0;
if (argument2 > 0)
{
    travelled = botReflexTravelledFrom(pr);
    if (travelled < argument2 * pr.speed)
        return false;
}
if (argument3 <= 0)
    return true;
roll = botReflexRoll(pr, argument1);
return (roll >= argument3);
