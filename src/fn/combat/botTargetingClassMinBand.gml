// botTargetingClassMinBand(class): BotTargeting.ClassMinBand - minimum engage
// distance.
switch (argument0)
{
    case CLASS_SOLDIER: return BOT_SPLASH_SAFE;
    case CLASS_DEMOMAN: return BOT_SPLASH_SAFE;
    case CLASS_PYRO: return 0;
    case CLASS_SPY: return 0;
    case CLASS_MEDIC: return 0;
}
return BOT_MIN_ENGAGE;
