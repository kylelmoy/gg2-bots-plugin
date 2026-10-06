// botHybridReleaseWheel(player): HybridBot.ReleaseWheel - the scripted layer
// takes the wheel back, if a tier had it.
var pl;
pl = argument0;
if (pl.botHybridDriving < 0)
    exit;
botPolicyOnHandoverOut(pl);
botHybridNoteHandover(pl, -1);
pl.botHybridDriving = -1;
