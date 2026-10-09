// botTargetingClassRange(class): BotTargeting.ClassRange - attention radius,
// not weapon range.
switch (argument0)
{
    case CLASS_SCOUT: return 220;
    case CLASS_SOLDIER: return 800;
    case CLASS_SNIPER: return 900;
    case CLASS_DEMOMAN: return 500;
    case CLASS_MEDIC: return 300;
    case CLASS_ENGINEER: return 400;
    case CLASS_HEAVY: return 500;
    case CLASS_SPY: return 300;
    case CLASS_PYRO: return 200;
    case CLASS_QUOTE: return 300;
}
return 375;
