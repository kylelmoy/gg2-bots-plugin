// botConfigLoad(): read [Bots] and [BotClasslimits] from gg2.ini (the C# server's
// keys). Defaults differ: Enabled=1; class limits from the C# server's
// deploy/config/common.ini.
ini_open("gg2.ini");
global.botEnabled = ini_read_real("Bots", "Enabled", 1);
global.botFillToPlayers = ini_read_real("Bots", "FillToPlayers", 8);
global.botMaxBots = ini_read_real("Bots", "MaxBots", 8);
global.botMinHumans = ini_read_real("Bots", "MinHumans", 1);
global.botDifficulty = max(1, min(5, ini_read_real("Bots", "Difficulty", 5)));
// Windows' ini reader trims the default, so "~" stands in; quote a value to
// keep a trailing space.
global.botNamePrefix = ini_read_string("Bots", "NamePrefix", "~");
if (global.botNamePrefix == "~")
    global.botNamePrefix = "[BOT] ";
// "scripted" or "policy" (policy takes over in fights).
global.botMode = string_lower(ini_read_string("Bots", "Mode", "policy"));
// Policy handover against bots too, or humans only (the C# server's
// --bot-engages-bots).
global.botEngagesBots = ini_read_real("Bots", "EngagesBots", 0);
global.botHandoverBubbles = ini_read_real("Bots", "HandoverBubbles", 0);
global.botOccupancyOn = ini_read_real("Bots", "Occupancy", 1);
global.botNavDistancesOn = ini_read_real("Bots", "NavDistances", 1);
// Generate a nav graph for maps without one.
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
