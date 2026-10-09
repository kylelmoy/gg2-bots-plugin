// botScriptedUnderFireWithNoAnswer(player, char):
// ScriptedBot.UnderFireWithNoAnswer - hit with no target, or one beyond class
// range. Shortens the parked timer.
var p, char, hit;
p = argument0;
char = argument1;
hit = botTargetingUnderFire(p);
if (!hit)
    return false;
if (!p.botCombatTargetExists)
    return true;
hit = botTargetingClassRange(p.class);
return point_distance(char.x, char.y, p.botCombatTargetX, p.botCombatTargetY) > hit;
