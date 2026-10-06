// botHybridTakeWheel(player, tier, char): HybridBot.TakeWheel - `tier` takes
// the wheel. The tier giving it up abandons its decision; the bubble is noted
// before the driver changes; absolute aim is resynced on every handover in.
var pl, tier, ch;
pl = argument0;
tier = argument1;
ch = argument2;
if (tier == pl.botHybridDriving)
    exit;
if (pl.botHybridDriving >= 0)
    botPolicyOnHandoverOut(pl);
botHybridNoteHandover(pl, tier);
pl.botHybridDriving = tier;
botPolicyOnHandoverIn(pl, ch);
