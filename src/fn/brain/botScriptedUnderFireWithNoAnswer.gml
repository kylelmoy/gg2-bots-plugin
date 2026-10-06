// botScriptedUnderFireWithNoAnswer(player, char): ScriptedBot.UnderFireWithNoAnswer -
// being shot with nothing to shoot back at (no target, or one beyond this
// class's range), which shortens the parked timer from eight seconds to half
// a second.
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
