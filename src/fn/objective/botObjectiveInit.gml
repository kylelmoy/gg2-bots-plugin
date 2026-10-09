// botObjectiveInit(player): per-bot BotObjective state on the Player (C#
// _spotNode, _spotAnchorX/Y, _spotMin/_spotMax/_spotHigh/_spotLos). Called once
// on join. botObjectiveSpotGen: map generation (global.botSpawnsGen) the held
// node belongs to.
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
