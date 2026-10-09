// botCombatSlew(player): BotCombat.Slew - turns botCombatAimDir toward
// botCombatAimWant at botSkillTurnRate deg/tick, snapping within one tick;
// result in [0, 360).
var p, e, delta, a;
p = argument0;
e = p.botCombatAimWant - p.botCombatAimDir + 180;
delta = e - 360 * floor(e / 360) - 180;
if (abs(delta) <= p.botSkillTurnRate)
    a = p.botCombatAimWant;
else
    a = p.botCombatAimDir + sign(delta) * p.botSkillTurnRate;
p.botCombatAimDir = a - 360 * floor(a / 360);
