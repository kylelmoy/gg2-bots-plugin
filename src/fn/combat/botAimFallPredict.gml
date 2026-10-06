// botAimFallPredict(y, vy, t, floorY): BotAim.FallPredict - botFallPredict.gml.
// Where a falling target will be in t ticks: accelerating at
// NAV_JUMP_GRAVITY until NAV_JUMP_TERM_VY, then constant, and clamped at the
// floor under it. botAimLead inlines this same formula in its loop.
var ty, vy, t, clampTicks, predicted;
ty = argument0;
vy = argument1;
t = argument2;
clampTicks = 0;
if (vy < NAV_JUMP_TERM_VY)
    clampTicks = (NAV_JUMP_TERM_VY - vy) / NAV_JUMP_GRAVITY;
if (t <= clampTicks)
    predicted = ty + vy * t + NAV_JUMP_GRAVITY * t * t / 2;
else
    predicted = ty + vy * clampTicks + NAV_JUMP_GRAVITY * clampTicks * clampTicks / 2
                + NAV_JUMP_TERM_VY * (t - clampTicks);
return min(predicted, argument3);
