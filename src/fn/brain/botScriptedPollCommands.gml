// botScriptedPollCommands(player): ScriptedBot.PollCommands - client commands
// (drop intel, sniper zoom) sent on the bot's own socket.
var p, char, wantsZoom;
p = argument0;

if (p.botScriptedDropIntel)
{
    p.botScriptedDropIntel = false;
    botSendByte(p, DROP_INTEL, -1);
}

// Sniper zooms while combat holds a target, grace period included.
char = p.object;
if (char == -1)
    exit;
if (p.class != CLASS_SNIPER)
    exit;
wantsZoom = (p.botCombatTargetExists != char.zoomed);
// Commands land next tick (the C#: same tick); don't re-toggle before then.
if (wantsZoom and global.botTick - p.botScriptedZoomSentAt > 3)
{
    p.botScriptedZoomSentAt = global.botTick;
    botSendByte(p, TOGGLE_ZOOM, -1);
}
