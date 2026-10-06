// botPolicyAtDecisionBoundary(player): PolicyController.AtDecisionBoundary -
// whether the next poll starts a new decision.
//
// The C# also answers true for a different slot than the one it last drove;
// here the state lives on the bot's own Player, so there is no other slot.
// And there is ONE policy state per bot, not one per tier: a tier that is not
// driving has had OnHandoverOut (or never drove), so its counter is 0 and it
// is at a boundary - the only tier whose cadence matters is the driving one.
return argument0.botPolicyTicksLeftInDecision <= 0;
