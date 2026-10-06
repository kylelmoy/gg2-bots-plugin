// botReflexRoll(projectile, player): BotReflex.Roll - a uniform [0, 1) fixed
// by the projectile and the bot: the same answer every tick, a different one
// per bot, and no draw from random().
// DEPARTURE (docs/departures/combat.md): GM8 has no 64-bit integers, so this
// is the classic fract(sin(dot) * 43758.5453) hash of the two instance ids
// rather than SplitMix64 of a projectile handle and a slot.
var h;
h = abs(sin(argument0 * 12.9898 + argument1 * 78.233)) * 43758.5453;
return h - floor(h);
