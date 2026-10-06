// botSkillLerp(skill, v0, v1, v2, v3): BotSkill.Lerp - botSkillLerp.gml.
// A four-anchor piecewise ramp, flat below 0.15 and above 0.95; the three
// segments are 0.15-0.45, 0.45-0.75 and 0.75-0.95 (the last is narrower on
// purpose, so the top tier moves further per point of skill).
var s;
s = argument0;
if (s <= 0.15)
    return argument1;
if (s >= 0.95)
    return argument4;
if (s <= 0.45)
    return argument1 + (argument2 - argument1) * (s - 0.15) / 0.3;
if (s <= 0.75)
    return argument2 + (argument3 - argument2) * (s - 0.45) / 0.3;
return argument3 + (argument4 - argument3) * (s - 0.75) / 0.2;
