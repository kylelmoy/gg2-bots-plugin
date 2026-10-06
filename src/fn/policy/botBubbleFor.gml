// botBubbleFor(taking): HandoverBubble.For - the bubble a handover asks for:
// -1 (the scripted layer taking it back) is z2, 21; a tier is z1, 20, since
// every GML tier is a policy (the C# keys this off the controller's name, and
// gives the rollout search z3, 22, which has no GML port). The indices are the
// client's own z menu (BubbleMenuZ). Returns -1 for a handover nothing
// depicts, which here is none.
if (argument0 < 0)
    return BOT_BUBBLE_LEFT_CONTROLLER;
return BOT_BUBBLE_TOOK_POLICY;
