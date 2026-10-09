// botBubbleFor(taking): HandoverBubble.For - bubble index (BubbleMenuZ) for
// a handover: scripted (-1) is z2 (21), any tier z1 (20).
// Departure: every GML tier is a policy; no rollout-search bubble.
if (argument0 < 0)
    return BOT_BUBBLE_LEFT_CONTROLLER;
return BOT_BUBBLE_TOOK_POLICY;
