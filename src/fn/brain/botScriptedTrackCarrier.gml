// botScriptedTrackCarrier(player, char): ScriptedBot.TrackCarrierProgress -
// the stuck-carrier failsafe. A carrier that makes no headway for
// BOT_SCRIPTED_CARRIER_STUCK_TICKS, or has held the intel for
// BOT_SCRIPTED_CARRIER_HOLD_CEILING whatever it is doing, asks once to drop it
// (sent by botScriptedPollCommands) and re-arms from wherever the drop leaves it.
var p, char;
p = argument0;
char = argument1;

if (!char.intel)
{
    p.botScriptedCarrierStuckSince = -1;
    p.botScriptedCarryingSince = -1;
    p.botScriptedCarrierStuckTicksNow = 0;
    exit;
}

if (p.botScriptedCarryingSince < 0)
    p.botScriptedCarryingSince = global.botTick;

// The hard ceiling first: a bot circling a pair of surfaces is moving.
if (global.botTick - p.botScriptedCarryingSince >= BOT_SCRIPTED_CARRIER_HOLD_CEILING)
{
    p.botScriptedDropIntel = true;
    p.botScriptedCarryingSince = global.botTick;
    p.botScriptedCarrierStuckSince = -1;
    p.botScriptedCarrierStuckTicksNow = 0;
    exit;
}

if (p.botScriptedCarrierStuckSince < 0
    or point_distance(char.x, char.y, p.botScriptedCarrierMarkX, p.botScriptedCarrierMarkY) > BOT_SCRIPTED_CARRIER_PROGRESS_DISTANCE)
{
    p.botScriptedCarrierMarkX = char.x;
    p.botScriptedCarrierMarkY = char.y;
    p.botScriptedCarrierStuckSince = global.botTick;
    p.botScriptedCarrierStuckTicksNow = 0;
    exit;
}

p.botScriptedCarrierStuckTicksNow = global.botTick - p.botScriptedCarrierStuckSince;
if (p.botScriptedCarrierStuckTicksNow < BOT_SCRIPTED_CARRIER_STUCK_TICKS)
    exit;

p.botScriptedDropIntel = true;
p.botScriptedCarrierStuckSince = -1;
p.botScriptedCarrierStuckTicksNow = 0;
