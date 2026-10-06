// botScriptedPollCommands(player): ScriptedBot.PollCommands - the actions that
// are client commands rather than key bits, sent on the bot's own socket and
// handled by processClientCommands like anybody's.
var p, char, wantsZoom;
p = argument0;

if (p.botScriptedDropIntel)
{
    p.botScriptedDropIntel = false;
    botSendByte(p, DROP_INTEL, -1);
}

// WantsZoom: a sniper zooms exactly while combat holds a target - including its
// grace after the sightline breaks, so it does not unscope behind every post.
char = p.object;
if (char == -1)
    exit;
if (p.class != CLASS_SNIPER)
    exit;
wantsZoom = (p.botCombatTargetExists != char.zoomed);
// A command reaches the game on the next tick, not this one as in gg2-server,
// so a second toggle before the first has landed would undo it.
if (wantsZoom and global.botTick - p.botScriptedZoomSentAt > 3)
{
    p.botScriptedZoomSentAt = global.botTick;
    botSendByte(p, TOGGLE_ZOOM, -1);
}
