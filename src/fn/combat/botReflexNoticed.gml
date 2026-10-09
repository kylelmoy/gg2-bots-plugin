// botReflexNoticed(projectile, player, reflexTicks, missChance):
// BotReflex.Noticed - has the bot seen it: flown reflexTicks * its speed, then
// a fixed miss roll (botReflexRoll).
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
