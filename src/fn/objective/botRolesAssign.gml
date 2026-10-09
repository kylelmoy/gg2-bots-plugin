// botRolesAssign(class, earlier): BotRoles.Assign(PlayerClass,
// ReadOnlySpan<PlayerClass>)
// - BOT_ROLE_ATTACK or BOT_ROLE_DEFEND. `earlier`: ds_list of classes of this
//   team's bots ahead of this one, in roster order. Counts earlier bots with
//   the same DefendEvery.
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
