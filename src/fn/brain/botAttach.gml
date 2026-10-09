// botAttach(player): a bot joined; init every module's per-bot state.
// Stagger = join order; offsets the objective-scan and re-plan cadences.
var p, s;
p = argument0;
s = global.botNextStagger;
global.botNextStagger += 1;
botPathInit(p);
botFollowerInit(p);
botCombatInit(p);
botObjectiveInit(p);
botScriptedInit(p);
botHybridInit(p);
p.botPathReplanStagger = s;
p.botCombatStagger = s;
p.botBrainStagger = s;
