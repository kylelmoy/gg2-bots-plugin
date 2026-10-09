// botStepSafe(char, dir): BotStep.Safe - does one BOT_ENGAGE_STEP in dir
// (-1/+1) land clear with Obstacle within BOT_ENGAGE_DROP below. place_meeting
// only, not place_free.
var c, d, ahead, safe;
c = argument0;
d = argument1;
safe = false;
if (c == -1)
    return false;
with (c)
{
    ahead = x + d * BOT_ENGAGE_STEP;
    if (!place_meeting(ahead, y, Obstacle))
        safe = place_meeting(ahead, y + BOT_ENGAGE_DROP, Obstacle);
}
return safe;
