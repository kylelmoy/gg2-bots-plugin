// botClassProfileAimError(class): BotClassProfile.AimError - how much of the
// difficulty's aim error this class carries (a multiplier on the knob).
switch (argument0)
{
    case CLASS_SOLDIER: return BOT_CP_AIM_ERR_TIGHT;
    case CLASS_HEAVY: return BOT_CP_AIM_ERR_LOOSE;
    case CLASS_SNIPER: return BOT_CP_AIM_ERR_SNIPER;
}
return 1;
