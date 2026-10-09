// botReflexRoll(projectile, player): BotReflex.Roll - uniform [0, 1) fixed per
// projectile and bot. DEPARTURE: fract(sin(dot) * 43758.5453) of the instance
// ids, not SplitMix64 (no 64-bit ints).
var h;
h = abs(sin(argument0 * 12.9898 + argument1 * 78.233)) * 43758.5453;
return h - floor(h);
