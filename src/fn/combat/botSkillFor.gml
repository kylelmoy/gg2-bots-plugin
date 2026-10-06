// botSkillFor(player, skill): BotSkill.For - botSkillApply.gml.
// Writes the difficulty knobs for a skill in [0, 1] onto the Player as
// botSkill<Knob> (the C# returns a BotSkill struct; one exists per bot, so its
// fields live on the Player - PORTING.md "Per-bot state"):
//   botSkillAcquireTicks, botSkillFireDelayTicks, botSkillPerceiveTicks,
//   botSkillAimInterval, botSkillTurnRate, botSkillAimErrorDeg,
//   botSkillAimConeDeg, botSkillMoveErrorMultiplier, botSkillHoldFireChance,
//   botSkillSplashAim, botSkillLeadMode, botSkillReflexTicks,
//   botSkillReflexMissChance, botSkillPolicyAimErrorDeg
// and botSkillSkill, the clamped skill itself.
// Tick counts are floor(x + 0.5) - round-half-up, NOT GM8's banker's round() -
// as the reference writes them.
var p, s, v;
p = argument0;
s = max(0, min(1, argument1));
p.botSkillSkill = s;

v = botSkillLerp(s, 30, 15, 9, 6);
p.botSkillAcquireTicks = floor(v + 0.5);
v = botSkillLerp(s, 45, 21, 10, 0);
p.botSkillFireDelayTicks = floor(v + 0.5);
v = botSkillLerp(s, 15, 10, 5, 1);
p.botSkillPerceiveTicks = max(1, floor(v + 0.5));
v = botSkillLerp(s, 8, 5, 3, 2);
p.botSkillAimInterval = max(1, floor(v + 0.5));
v = botSkillLerp(s, 6, 7.5, 9, 24);
p.botSkillTurnRate = v;
v = botSkillLerp(s, 4, 1.5, 0.5, 0.2);
p.botSkillAimErrorDeg = v;
v = botSkillLerp(s, 20, 10, 4, 1);
p.botSkillAimConeDeg = v;
v = botSkillLerp(s, 1, 0.6, 0.4, 0.3);
p.botSkillMoveErrorMultiplier = v;
v = botSkillLerp(s, 0.35, 0.15, 0.05, 0);
p.botSkillHoldFireChance = v;

// A step rather than a ramp: knowing to aim at somebody's feet is a thing you
// have learnt or have not.
p.botSkillSplashAim = (s >= 0.6);

// Every tier solves the full intercept.
p.botSkillLeadMode = BOT_LEAD_FULL;

v = botSkillLerp(s, 9, 6, 3, 0);
p.botSkillReflexTicks = floor(v + 0.5);
v = botSkillLerp(s, 0.6, 0.35, 0.15, 0);
p.botSkillReflexMissChance = v;
v = botSkillLerp(s, 12, 6, 2, 0);
p.botSkillPolicyAimErrorDeg = v;
