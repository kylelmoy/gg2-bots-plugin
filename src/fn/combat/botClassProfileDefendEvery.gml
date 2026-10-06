// botClassProfileDefendEvery(class): BotClassProfile.DefendEvery - one bot in
// every N of this class's lean group defends. A period, not a veto - except
// the medic, BOT_DEFEND_NEVER (0), which also drops medics out of every other
// class's lean-group count.
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
