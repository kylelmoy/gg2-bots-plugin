// botActionDecoderTurnFor(bin): ActionDecoder.TurnFor - degrees for an aim
// bin (0 full left, 7 none, 14 full right; out of range: none).
var b;
b = argument0;
if (b >= BOT_ACTION_AIM_BINS or b < 0)
    b = BOT_ACTION_AIM_CENTRE;
return (b - BOT_ACTION_AIM_CENTRE) * (BOT_ACTION_MAX_TURN / BOT_ACTION_AIM_CENTRE);
