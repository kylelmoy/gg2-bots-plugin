// botPopulationReclass(): BotPopulationService.Reclass. A bot that has just
// died, or whose class is over its limit, picks again while it waits to
// respawn - so a team's mix keeps moving rather than freezing at whatever the
// first draw was - and is renamed to match.
var alive, died, over, n, c, playerId, nm;
with (Player)
{
    if (!botIsBot)
        continue;
    if (variable_local_exists("botLeaving"))
        continue;
    alive = (object != -1);
    died = botWasAlive and !alive;
    botWasAlive = alive;
    if (team != TEAM_RED and team != TEAM_BLUE)
        continue;
    if (alive)
        continue;
    n = 0;
    with (Player)
        if (botIsBot and id != other.id and team == other.team and class == other.class)
            n += 1;
    over = (class > CLASS_PYRO);
    if (!over)
        over = (n >= global.botClassLimit[class]);
    if (!(died or over))
        continue;
    c = botPickClassFor(id, team);
    if (c < 0 or c == class)
        continue;
    botSendByte(id, PLAYER_CHANGECLASS, c);
    nm = global.botNamePrefix + global.botClassName[c];
    name = nm;
    playerId = ds_list_find_index(global.players, id);
    write_ubyte(global.sendBuffer, PLAYER_CHANGENAME);
    write_ubyte(global.sendBuffer, playerId);
    write_ubyte(global.sendBuffer, string_length(nm));
    write_string(global.sendBuffer, nm);
}
