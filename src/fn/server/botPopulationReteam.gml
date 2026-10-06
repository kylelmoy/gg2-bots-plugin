// botPopulationReteam(): BotPopulationService.Reteam. A bot on no team asks
// for the smaller one - after a map change (serverGotoMap leaves everybody on
// spectator) and after joining, should the first request have been refused.
// At most once a second per bot: the request is answered next tick, and a
// refusal (team balance) should not be asked again every frame.
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
