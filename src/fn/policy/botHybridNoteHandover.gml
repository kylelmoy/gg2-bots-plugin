// botHybridNoteHandover(player, next): HybridBot.NoteHandover - remember the
// bubble a handover to `next` (a tier, or -1 for the scripted layer) asks for,
// for botHybridPollCommands to send. Overwritten, not queued: the last one
// describes the state the bot is actually in. Only when global.botHandoverBubbles.
var pl, image;
pl = argument0;
if (!global.botHandoverBubbles)
    exit;
image = botBubbleFor(argument1);
if (image >= 0)
    pl.botHybridBubble = image;
