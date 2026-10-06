// botHybridPollCommands(player): HybridBot.PollCommands - commands (team and
// class choice, drops, taunts) always come from the scripted layer; a combat
// controller has no command head. Then, when a handover asked for one, the
// bubble.
//
// AFTER the scripted layer's commands, never before (the C#'s buffer has a
// per-tick ceiling a debugging aid must not take from a real command). No two
// bubbles within BOT_HYBRID_BUBBLE_SPACING calls (300 ms at 30 Hz), against
// the server's own 250 ms per-player bubble throttle, which drops one in
// silence; a bubble that would put back what clients already show is dropped.
//
// gg2-server calls PollCommands before Poll in a tick, so a bubble trails its
// handover by a tick; when the integrator calls this relative to
// botHybridPoll decides that here.
var pl, image;
pl = argument0;
botScriptedPollCommands(pl);
pl.botHybridCommandPolls += 1;
image = pl.botHybridBubble;
if (image < 0)
    exit;
if (pl.botHybridCommandPolls - pl.botHybridBubbleSentAt < BOT_HYBRID_BUBBLE_SPACING)
{
    if (image == pl.botHybridBubbleShown)
        pl.botHybridBubble = -1;
    exit;
}
botSendByte(pl, CHAT_BUBBLE, image);
pl.botHybridBubble = -1;
pl.botHybridBubbleShown = image;
pl.botHybridBubbleSentAt = pl.botHybridCommandPolls;
