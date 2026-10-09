// botPolicyPoll(player, char, tier): PolicyController.Poll - this tick's
// input from `tier`; returns as botActionDecoderDecode. Sets
// player.botPolicyDecidedThisPoll.
// The net runs once per ActionRepeat ticks; held ticks re-decode the same
// action.
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
