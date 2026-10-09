// botClassProfileSpotMode(class): BotClassProfile.SpotMode -
// BOT_SPOT_NONE/STANDOFF/ CHOKE/FLANK.
switch (argument0)
{
    case CLASS_SNIPER:
    case CLASS_HEAVY:
    case CLASS_DEMOMAN:
        return BOT_SPOT_STANDOFF;
    case CLASS_ENGINEER:
        return BOT_SPOT_CHOKE;
    case CLASS_SPY:
        return BOT_SPOT_FLANK;
}
return BOT_SPOT_NONE;
