// botCombatSlew(player): BotCombat.Slew - turns botCombatAimDir towards
// botCombatAimWant at botSkillTurnRate degrees a tick, SNAPPING when within
// one tick's turn (otherwise the aim oscillates and the settle gate never
// opens), then normalises into [0, 360). botTargetingAngleDelta is inlined.
var p, e, delta, a;
p = argument0;
e = p.botCombatAimWant - p.botCombatAimDir + 180;
delta = e - 360 * floor(e / 360) - 180;
if (abs(delta) <= p.botSkillTurnRate)
    a = p.botCombatAimWant;
else
    a = p.botCombatAimDir + sign(delta) * p.botSkillTurnRate;
p.botCombatAimDir = a - 360 * floor(a / 360);
