// botAttach(player): a bot has just joined. Every module's per-bot state, in
// one place, so a module's fields exist before anything reads them.
//
// The stagger is gg2-server's roster slot at the time the bot was added: both
// cadences (the objective scan, the re-plan) are offset by it so a server full
// of bots does not do all of its expensive work on one tick.
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
