// botActionDecoderTurnFor(bin): ActionDecoder.TurnFor - degrees for an aim
// bin. Bin 0 is a full left turn, 7 none, 14 a full right turn, each 30/7
// degrees apart; an out-of-range bin is no turn.
var b;
b = argument0;
if (b >= BOT_ACTION_AIM_BINS or b < 0)
    b = BOT_ACTION_AIM_CENTRE;
return (b - BOT_ACTION_AIM_CENTRE) * (BOT_ACTION_MAX_TURN / BOT_ACTION_AIM_CENTRE);
