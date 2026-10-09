// botHybridPollCommands(player): HybridBot.PollCommands - the scripted
// layer's commands, then any pending handover bubble.
// Bubbles at least BOT_HYBRID_BUBBLE_SPACING calls apart (server throttles
// at 250 ms); one matching what clients show is dropped.
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
