// botRolesAssignPlace(class, placeInGroup): BotRoles.Assign(PlayerClass, int) -
// BOT_ROLE_ATTACK/BOT_ROLE_DEFEND. placeInGroup: index among team bots sharing
// its DefendEvery. Veto tested before mod (no divide by zero); first of a group
// always attacks.
var cls, place, every;
cls = argument0;
place = argument1;

every = botClassProfileDefendEvery(cls);
if (every <= BOT_DEFEND_NEVER)
    return BOT_ROLE_ATTACK;

if ((place + 1) mod every == 0)
    return BOT_ROLE_DEFEND;
return BOT_ROLE_ATTACK;
