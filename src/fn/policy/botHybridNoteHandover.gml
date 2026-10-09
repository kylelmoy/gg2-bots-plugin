// botHybridNoteHandover(player, next): HybridBot.NoteHandover - note the
// bubble for a handover to `next` (tier, or -1 scripted) for
// botHybridPollCommands. Overwrites, not queued. Only when
// global.botHandoverBubbles.
var pl, image;
pl = argument0;
if (!global.botHandoverBubbles)
    exit;
image = botBubbleFor(argument1);
if (image >= 0)
    pl.botHybridBubble = image;
