// botHybridInit(player): initialise the per-bot fields of HybridBot,
// PolicyController and ActionDecoder.
// botHybridDriving: tier at the wheel, -1 scripted.
// botHybridBubble/BubbleShown: -1 none. BubbleSentAt: in CommandPolls.
// ScriptedPolls == MicroTicks + ScriptedTicks.
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
