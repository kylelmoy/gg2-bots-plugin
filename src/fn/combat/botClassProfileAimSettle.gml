// botClassProfileAimSettle(class): BotClassProfile.AimSettle - a multiplier on
// BOT_AIM_SETTLE_DEG. A heavy may fire while still turning; a sniper may not.
switch (argument0)
{
    case CLASS_HEAVY: return BOT_CP_SETTLE_LOOSE;
    case CLASS_SNIPER: return BOT_CP_SETTLE_TIGHT;
}
return 1;
