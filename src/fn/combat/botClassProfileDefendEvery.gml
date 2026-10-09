// botClassProfileDefendEvery(class): BotClassProfile.DefendEvery - one in every
// N of the lean group defends. Medic: BOT_DEFEND_NEVER (0), also excluded from
// other counts.
switch (argument0)
{
    case CLASS_ENGINEER:
    case CLASS_HEAVY:
        return BOT_DEFEND_KEEN;
    case CLASS_SCOUT:
    case CLASS_SPY:
        return BOT_DEFEND_AVERSE;
    case CLASS_MEDIC:
        return BOT_DEFEND_NEVER;
}
return BOT_DEFEND_EVERY;
