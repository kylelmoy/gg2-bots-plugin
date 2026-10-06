// botCombatSpread(errorDeg, coneDeg, moveMultiplier, moving, sinceSeen,
//                 distance): BotCombat.Spread - botAimSpread.gml.
// How far off the aim may be: a floor plus a cone that decays the longer the
// target is watched, scaled by the moving multiplier, and DIVIDED by Quake
// III's close-range factor (below 1 near the target, so it widens the spread
// at point blank for every tier).
var spread, closeFactor;
spread = argument0 + argument1 * power(BOT_AIM_CONE_DECAY, max(0, argument4));
if (argument3)
    spread *= argument2;
closeFactor = BOT_CLOSE_PENALTY
              + min(max(0, argument5), BOT_CLOSE_RANGE) / BOT_CLOSE_RANGE * (1 - BOT_CLOSE_PENALTY);
return spread / closeFactor;
