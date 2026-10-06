// botThink(player, char): one bot, one tick. Commands first and then input, the
// order gg2-server's GameServer.Tick asks a bot in. char is player.object,
// -1 when dead. Returns keys in global.botRet, aim in global.botRetAim and aim
// distance in global.botRetAimDist (botPoll writes them onto the character).
botHybridPollCommands(argument0);
return botHybridPoll(argument0, argument1);
