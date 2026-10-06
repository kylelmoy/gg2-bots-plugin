// botTargetingClassMinBand(class): BotTargeting.ClassMinBand -
// botClassMinBand.gml. How close is too close: the splash classes keep out of
// their own blast, the pyro, spy and medic have no minimum, everyone else
// BOT_MIN_ENGAGE.
switch (argument0)
{
    case CLASS_SOLDIER: return BOT_SPLASH_SAFE;
    case CLASS_DEMOMAN: return BOT_SPLASH_SAFE;
    case CLASS_PYRO: return 0;
    case CLASS_SPY: return 0;
    case CLASS_MEDIC: return 0;
}
return BOT_MIN_ENGAGE;
