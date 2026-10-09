// botClassProfileAimSettle(class): BotClassProfile.AimSettle - multiplier on
// BOT_AIM_SETTLE_DEG.
switch (argument0)
{
    case CLASS_HEAVY: return BOT_CP_SETTLE_LOOSE;
    case CLASS_SNIPER: return BOT_CP_SETTLE_TIGHT;
}
return 1;
