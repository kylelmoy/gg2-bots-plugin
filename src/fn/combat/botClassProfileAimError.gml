// botClassProfileAimError(class): BotClassProfile.AimError - multiplier on the
// difficulty's aim error.
switch (argument0)
{
    case CLASS_SOLDIER: return BOT_CP_AIM_ERR_TIGHT;
    case CLASS_HEAVY: return BOT_CP_AIM_ERR_LOOSE;
    case CLASS_SNIPER: return BOT_CP_AIM_ERR_SNIPER;
}
return 1;
