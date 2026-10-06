// botTargetingAngleDelta(a, b): BotTargeting.AngleDelta - botAngleDelta.gml.
// The signed difference a - b in [-180, 180); exactly opposite gives -180.
// Written with floor rather than `mod` so it is exact for real operands; the
// result is the C#'s ((d % 360 + 540) % 360) - 180 for every input.
var e;
e = argument0 - argument1 + 180;
return e - 360 * floor(e / 360) - 180;
