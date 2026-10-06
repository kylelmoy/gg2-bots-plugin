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
var t0, spent;
if (!variable_global_exists("botJoining"))
    exit;

t0 = current_time;
botJoinService();

if (global.run_virtual_ticks)
{
    global.botTick += 1;
    botNavMapCheck();
    botPopulationService();
    botBrainService();
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

// What the bot layer costs, in the only clock GM8 has (1-16 ms granularity, so
// read the sum over many ticks, not one tick). botStatsReset() zeroes it.
spent = current_time - t0;
global.botCostSum += spent;
global.botCostTicks += 1;
if (spent > global.botCostMax)
    global.botCostMax = spent;
