// botStepSafe(char, dir): BotStep.Safe - botStepSafe.gml. Whether one
// BOT_ENGAGE_STEP in dir (-1 left, +1 right) lands somewhere with ground under
// it: no Obstacle where the character's own mask would stand, and an Obstacle
// within BOT_ENGAGE_DROP below that. place_meeting against Obstacle ALONE -
// never place_free, whose answer depends on where in the frame the solids
// flags happen to be.
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
