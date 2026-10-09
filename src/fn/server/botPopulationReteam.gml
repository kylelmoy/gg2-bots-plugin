// botPopulationReteam(): BotPopulationService.Reteam - a bot on no team (after
// a map change or a refused request) asks for the smaller one, at most once a
// second.
var red, blue, t;
with (Player)
{
    if (!botIsBot)
        continue;
    if (variable_local_exists("botLeaving"))
        continue;
    if (team == TEAM_RED or team == TEAM_BLUE)
        continue;
    if (global.botTick - botLastTeamAsk < 30)
        continue;
    botLastTeamAsk = global.botTick;
    botCountTeams();
    red = global.botRet;
    blue = global.botRetBlue;
    t = botPickTeam(red, blue);
    botSendByte(id, PLAYER_CHANGETEAM, t);
}
