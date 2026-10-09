// botTargetingAngleDelta(a, b): BotTargeting.AngleDelta - signed a - b in
// [-180, 180); floor, not mod, for real operands.
var e;
e = argument0 - argument1 + 180;
return e - 360 * floor(e / 360) - 180;
