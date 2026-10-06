// botHybridScripted(player): HybridBot.Scripted - the scripted layer drives
// this tick: release the wheel and count it. The caller returns the scripted
// input it already holds (set global.botRet* AFTER this call: the release
// can call functions that use them).
var pl;
pl = argument0;
botHybridReleaseWheel(pl);
pl.botHybridMicroDrove = false;
pl.botHybridDecidedThisPoll = false;
pl.botHybridScriptedTicks += 1;
