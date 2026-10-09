// botCombatSpread(errorDeg, coneDeg, moveMultiplier, moving, sinceSeen,
//                 distance): BotCombat.Spread - aim error in degrees:
// floor plus a decaying cone, times moveMultiplier if moving, divided by the
// close-range factor (<1 near).
var spread, closeFactor;
spread = argument0 + argument1 * power(BOT_AIM_CONE_DECAY, max(0, argument4));
if (argument3)
    spread *= argument2;
closeFactor = BOT_CLOSE_PENALTY
              + min(max(0, argument5), BOT_CLOSE_RANGE) / BOT_CLOSE_RANGE * (1 - BOT_CLOSE_PENALTY);
return spread / closeFactor;
