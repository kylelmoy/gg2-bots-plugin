// botRolesAssignPlace(class, placeInGroup): BotRoles.Assign(PlayerClass, int)
// - the overload that takes the bot's position among its team's bots that share
// its BotClassProfile.DefendEvery period. Returns BOT_ROLE_ATTACK/BOT_ROLE_DEFEND.
//
// The medic veto (DefendEvery <= BOT_DEFEND_NEVER) is tested before the mod,
// which is also what keeps a zero period from dividing by zero. `(place + 1)`
// makes the first bot of a group an attacker every time.
var cls, place, every;
cls = argument0;
place = argument1;

every = botClassProfileDefendEvery(cls);
if (every <= BOT_DEFEND_NEVER)
    return BOT_ROLE_ATTACK;

if ((place + 1) mod every == 0)
    return BOT_ROLE_DEFEND;
return BOT_ROLE_ATTACK;
