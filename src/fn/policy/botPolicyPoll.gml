// botPolicyPoll(player, char, tier): PolicyController.Poll - this bot's keys
// and aim from policy tier `tier` (a global.botPolicyNet index) this tick.
// Returns as botActionDecoderDecode does: keys in global.botRet, aim in
// global.botRetAimNet (wire units) and global.botRetAim (degrees), distance in
// global.botRetAimDist. Sets player.botPolicyDecidedThisPoll.
//
// The network runs once per ActionRepeat ticks (4 for the shipped
// checkpoints), the cadence it was trained at; the held ticks are a
// different decode of the same action (no jump edge, no turn).
var pl, ch, tier, first;
pl = argument0;
ch = argument1;
tier = argument2;
first = botPolicyAtDecisionBoundary(pl);
pl.botPolicyDecidedThisPoll = first;
if (first)
{
    pl.botPolicyTicksLeftInDecision = max(1, global.botPolicyNetRepeat[tier]);
    botPolicyDecide(pl, ch, tier);
}
pl.botPolicyTicksLeftInDecision -= 1;
return botActionDecoderDecode(pl, first);
