// botConfigLoad(): read [Bots] and [BotClasslimits] from gg2.ini.
//
// The keys and their meaning are gg2-server's (docs/CONFIG.md there), so one
// gg2.ini section configures bots on either server. Two defaults differ, and
// both because installing this plugin is itself the request for bots:
// Enabled is 1, and the class limits are the ones gg2-server's own deployment
// ships with (deploy/config/common.ini) rather than its library default.
ini_open("gg2.ini");
global.botEnabled = ini_read_real("Bots", "Enabled", 1);
global.botFillToPlayers = ini_read_real("Bots", "FillToPlayers", 8);
global.botMaxBots = ini_read_real("Bots", "MaxBots", 8);
global.botMinHumans = ini_read_real("Bots", "MinHumans", 1);
global.botDifficulty = max(1, min(5, ini_read_real("Bots", "Difficulty", 5)));
global.botNamePrefix = ini_read_string("Bots", "NamePrefix", "[BOT] ");
// "scripted" or "policy": whether the learned policy takes the wheel in a fight.
global.botMode = string_lower(ini_read_string("Bots", "Mode", "policy"));
// Whether a bot hands its wheel to the policy against other bots too, or only
// against people (gg2-server's --bot-engages-bots; HumansOnly is the default
// there for a live server, and the reason is cost, which matters more here).
global.botEngagesBots = ini_read_real("Bots", "EngagesBots", 0);
global.botHandoverBubbles = ini_read_real("Bots", "HandoverBubbles", 0);
global.botOccupancyOn = ini_read_real("Bots", "Occupancy", 1);
global.botNavDistancesOn = ini_read_real("Bots", "NavDistances", 1);
// Whether a map with no nav graph gets one from the generator.
global.botNavGenerate = ini_read_real("Bots", "NavGenerate", 1);

global.botClassName[CLASS_SCOUT] = "Scout";
global.botClassName[CLASS_SOLDIER] = "Soldier";
global.botClassName[CLASS_SNIPER] = "Sniper";
global.botClassName[CLASS_DEMOMAN] = "Demoman";
global.botClassName[CLASS_MEDIC] = "Medic";
global.botClassName[CLASS_ENGINEER] = "Engineer";
global.botClassName[CLASS_HEAVY] = "Heavy";
global.botClassName[CLASS_SPY] = "Spy";
global.botClassName[CLASS_PYRO] = "Pyro";
global.botClassName[CLASS_QUOTE] = "Quote";
global.botClassLimit[CLASS_SCOUT] = ini_read_real("BotClasslimits", "Scout", 2);
global.botClassLimit[CLASS_SOLDIER] = ini_read_real("BotClasslimits", "Soldier", 2);
global.botClassLimit[CLASS_SNIPER] = ini_read_real("BotClasslimits", "Sniper", 1);
global.botClassLimit[CLASS_DEMOMAN] = ini_read_real("BotClasslimits", "Demoman", 2);
global.botClassLimit[CLASS_MEDIC] = ini_read_real("BotClasslimits", "Medic", 1);
global.botClassLimit[CLASS_ENGINEER] = ini_read_real("BotClasslimits", "Engineer", 2);
global.botClassLimit[CLASS_HEAVY] = ini_read_real("BotClasslimits", "Heavy", 2);
global.botClassLimit[CLASS_SPY] = ini_read_real("BotClasslimits", "Spy", 0);
global.botClassLimit[CLASS_PYRO] = ini_read_real("BotClasslimits", "Pyro", 2);
global.botClassLimit[CLASS_QUOTE] = 0;
ini_close();
