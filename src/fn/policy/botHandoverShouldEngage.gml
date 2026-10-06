// botHandoverShouldEngage(player, char, range, wantsToEngage, humansOnly,
// healTarget): Handover.ShouldEngage under HandoverRule.MacroTask, the only
// rule a live server runs - an enemy within `range` AND the scripted layer's
// own engage hold. The range half is not optional: the hold reaches out to
// the class's targeting range (800 px for a soldier), far past where the
// policy's observation saturates.
//
// A medic on the beam is never handed over (BotClassProfile.Heals, and the
// ally the combat module holds, botCombatAlly, still valid by
// botAllyStillValid): it has a job this tick that no trained policy knows.
// Only the range half is filtered by humansOnly.
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
