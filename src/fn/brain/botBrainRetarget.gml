// botBrainRetarget(full): BotPopulationService.Retarget (full) or Rerole (not).
// Role = BotRoles.Assign over classes of same-team bots in lower roster slots.
// Full also does ScriptedBot.Assign: spread, query team/air jump, a fresh
// objective layer.
var full, i, j, pl, other2, role, spread, airJump;
full = argument0;
for (i = 0; i < ds_list_size(global.players); i += 1)
{
    pl = ds_list_find_value(global.players, i);
    if (!pl.botIsBot)
        continue;
    ds_list_clear(global.botBrainEarlier);
    for (j = 0; j < i; j += 1)
    {
        other2 = ds_list_find_value(global.players, j);
        if (other2.botIsBot and other2.team == pl.team)
            ds_list_add(global.botBrainEarlier, other2.class);
    }
    role = botRolesAssign(pl.class, global.botBrainEarlier);
    pl.botScriptedRole = role;
    if (!full)
        continue;
    spread = botRolesSpreadX(pl.botBrainStagger);
    pl.botScriptedSpreadX = spread;
    airJump = botClassProfileAirJump(pl.class);
    pl.botScriptedQueryTeam = pl.team;
    pl.botScriptedQueryCanDoubleJump = airJump;
    botObjectiveFree(pl);
    botObjectiveInit(pl);
    pl.botScriptedHasObjective = global.botNavReady;
}
