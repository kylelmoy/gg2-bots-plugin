// botClassProfileSpotHigh(class): BotClassProfile.SpotHigh - how much this
// class values height when choosing where to stand (BotGoalSpot's highBonus
// units).
switch (argument0)
{
    case CLASS_SNIPER: return BOT_SPOT_HIGH_SNIPER;
    case CLASS_HEAVY: return BOT_SPOT_HIGH_BONUS;
    case CLASS_ENGINEER: return BOT_SPOT_HIGH_BONUS / 2;
}
return 0;
