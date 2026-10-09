// botHandoverShouldEngage(player, char, range, wantsToEngage, humansOnly,
// healTarget): Handover.ShouldEngage (HandoverRule.MacroTask) - an enemy
// within `range` and the scripted layer wants to engage. Never for a medic
// with a valid heal target. humansOnly filters the range test only.
var pl, ch, range, wants, hum, heal, valid, d, inRange;
pl = argument0;
ch = argument1;
range = argument2;
wants = argument3;
hum = argument4;
heal = argument5;
if (pl.class == CLASS_MEDIC)
{
    valid = botAllyStillValid(pl, heal);
    if (valid)
        return false;
}
d = botHandoverDistanceToNearestEnemy(pl, ch, hum);
inRange = false;
if (d >= 0)
    inRange = (d <= range);
return (inRange and wants);
