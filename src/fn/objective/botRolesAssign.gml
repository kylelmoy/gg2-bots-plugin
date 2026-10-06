// botRolesAssign(class, earlier): BotRoles.Assign(PlayerClass, ReadOnlySpan<PlayerClass>).
// `earlier` is a ds_list of the classes of this team's BOTS that come before
// this one on the roster, in roster order (the caller leaves out other teams
// and people). Returns BOT_ROLE_ATTACK or BOT_ROLE_DEFEND.
//
// Counts this bot's place in its lean group - the earlier bots whose
// DefendEvery period equals its own - and hands that to botRolesAssignPlace.
// A class that never defends (the medic) answers before counting, so it is in
// no lean group at all and cannot take the place a group's defender needed.
var cls, earlier, every, place, i, n, otherCls, otherEvery;
cls = argument0;
earlier = argument1;

every = botClassProfileDefendEvery(cls);
if (every <= BOT_DEFEND_NEVER)
    return BOT_ROLE_ATTACK;

place = 0;
n = ds_list_size(earlier);
for (i = 0; i < n; i += 1)
{
    otherCls = ds_list_find_value(earlier, i);
    otherEvery = botClassProfileDefendEvery(otherCls);
    if (otherEvery == every)
        place += 1;
}

return botRolesAssignPlace(cls, place);
