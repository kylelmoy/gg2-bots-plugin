// botBrainRetarget(full): BotPopulationService.Retarget (full) or Rerole (not).
//
// Each bot's role is BotRoles.Assign over the classes of the same team's bots
// in LOWER roster positions, so the every-Nth-defends rule lands the same way
// however the bots were added. A full retarget is ScriptedBot.Assign: also the
// lateral spread, the query's team and air jump, and a FRESH objective layer -
// the C# builds a new BotObjective every time, so none of its state survives.
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
