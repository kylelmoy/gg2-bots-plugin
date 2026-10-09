// Appended to GameServer's End Step, after the tick's broadcast and joiner
// servicing. Bots decide here, not Begin Step (already serialised): the next
// tick reads these keys, as a client's.
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
    // Drain the server's broadcasts to this bot.
    tcp_receive_available(botSock);
    if (variable_local_exists("botLeaving"))
        continue;
    if (global.run_virtual_ticks)
        botPoll(id);
}

// Cost; current_time is 1-16 ms granular, so read sums over many ticks.
spent = current_time - t0;
global.botCostSum += spent;
global.botCostTicks += 1;
if (spent > 20)
    global.botCostOver += 1;
if (spent > global.botCostMax)
    global.botCostMax = spent;
