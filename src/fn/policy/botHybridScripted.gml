// botHybridScripted(player): HybridBot.Scripted - the scripted layer drives
// this tick. Clobbers global.botRet*; caller sets them after.
var pl;
pl = argument0;
botHybridReleaseWheel(pl);
pl.botHybridMicroDrove = false;
pl.botHybridDecidedThisPoll = false;
pl.botHybridScriptedTicks += 1;
