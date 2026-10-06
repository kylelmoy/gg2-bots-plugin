// botHybridInit(player): every per-bot field the policy module owns, set once
// when the bot joins (HybridBot's, PolicyController's and ActionDecoder's
// fields; there is one of each per bot). Nothing here is a ds_ structure.
//
// HybridBot:
//   botHybridDriving          the tier holding the wheel, -1 for the scripted layer
//   botHybridBubble           the bubble a handover asked for, -1 for none
//   botHybridBubbleShown      the last bubble sent (what clients show), -1 for none
//   botHybridBubbleSentAt     the botHybridCommandPolls it went out on
//   botHybridCommandPolls     botHybridPollCommands calls so far (its own clock)
//   botHybridHandicapAim      aim error in wire units, held between draws
//   botHybridHandicapHoldFire the hold-fire roll of the current draw
//   botHybridHandicapTicksLeft controller-driven ticks until the next draw
//   botHybridMicroDrove, botHybridDecidedThisPoll   the last poll
//   botHybridMicroTicks, botHybridMicroDecisions, botHybridScriptedTicks,
//   botHybridScriptedPolls    counters; ScriptedPolls == MicroTicks + ScriptedTicks
// PolicyController / ActionDecoder:
//   botPolicyTicksLeftInDecision, botPolicyDecidedThisPoll,
//   botPolicyActionHorizontal, ...Jump, ...Down, ...Fire, ...AimDelta, ...Zoom,
//   botActionDecoderAim (degrees)
var pl;
pl = argument0;
pl.botHybridDriving = -1;
pl.botHybridBubble = -1;
pl.botHybridBubbleShown = -1;
pl.botHybridBubbleSentAt = -1000000;
pl.botHybridCommandPolls = 0;
pl.botHybridHandicapAim = 0;
pl.botHybridHandicapHoldFire = false;
pl.botHybridHandicapTicksLeft = 0;
pl.botHybridMicroDrove = false;
pl.botHybridDecidedThisPoll = false;
pl.botHybridMicroTicks = 0;
pl.botHybridMicroDecisions = 0;
pl.botHybridScriptedTicks = 0;
pl.botHybridScriptedPolls = 0;

pl.botPolicyTicksLeftInDecision = 0;
pl.botPolicyDecidedThisPoll = false;
pl.botPolicyActionHorizontal = 0;
pl.botPolicyActionJump = 0;
pl.botPolicyActionDown = 0;
pl.botPolicyActionFire = 0;
pl.botPolicyActionAimDelta = BOT_ACTION_AIM_CENTRE;
pl.botPolicyActionZoom = 0;
pl.botActionDecoderAim = 0;
