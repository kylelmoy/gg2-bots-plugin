// Appended to GameServer's End Step, after GameServerEndStep has broadcast this
// tick and serviced the joining players.
//
// Bots decide HERE, at the end of the tick, rather than in Begin Step beside
// processClientCommands. Begin Step serialises every character's keys for the
// broadcast (serializeState in GameServerBeginStep) straight after reading the
// clients' commands, and an appended event runs after that - so keys written
// there would reach the clients one tick after the server acted on them. Keys
// written now are in place before the next tick reads anybody's input, which
// is where a person's are.
if (!variable_global_exists("botJoining"))
    exit;

botJoinService();

if (global.run_virtual_ticks)
{
    global.botTick += 1;
    botNavMapCheck();
    botPopulationService();
}

with (Player)
{
    if (!botIsBot)
        continue;
    // The server's broadcasts to this bot's client end: never read, so drain.
    tcp_receive_available(botSock);
    if (variable_local_exists("botLeaving"))
        continue;
    if (global.run_virtual_ticks)
        botPoll(id);
}
