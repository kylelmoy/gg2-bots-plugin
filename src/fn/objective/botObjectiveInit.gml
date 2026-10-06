// botObjectiveInit(player): the per-bot half of BotObjective - the spot it last
// chose and the question it chose it for (C# _spotNode, _spotAnchorX/Y,
// _spotMin/_spotMax/_spotHigh/_spotLos), on the bot's Player. Called once when
// the bot joins. The graph and the spawn points are global (botSpawnsLoad).
//
// botObjectiveSpotGen is the map generation (global.botSpawnsGen) the held node
// belongs to: botObjectiveDecide drops a node from another map's graph, which is
// what building a fresh BotObjective per map does in the C#.
var bot;
bot = argument0;
bot.botObjectiveSpotNode = -1;
bot.botObjectiveSpotAnchorX = 0;
bot.botObjectiveSpotAnchorY = 0;
bot.botObjectiveSpotMin = 0;
bot.botObjectiveSpotMax = 0;
bot.botObjectiveSpotHigh = 0;
bot.botObjectiveSpotLos = BOT_LOS_ANY;
bot.botObjectiveSpotGen = -1;
