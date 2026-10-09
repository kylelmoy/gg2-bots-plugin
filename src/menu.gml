// The "Bots" tab of the host options menu: the Create event of the
// BotsMenuController that bots.gml makes. Plain GML, not transpiled; it runs
// before hosting, so nothing the bot layer defines exists yet. Binds the same
// globals botConfigLoad sets (it re-reads gg2.ini when hosting starts), with
// the same defaults; the settings it leaves out stay ini-only.
ini_open("gg2.ini");
global.botEnabled = ini_read_real("Bots", "Enabled", 1);
global.botFillToPlayers = ini_read_real("Bots", "FillToPlayers", 8);
global.botMaxBots = ini_read_real("Bots", "MaxBots", 8);
global.botMinHumans = ini_read_real("Bots", "MinHumans", 1);
global.botDifficulty = max(1, min(5, ini_read_real("Bots", "Difficulty", 5)));
global.botNamePrefix = ini_read_string("Bots", "NamePrefix", "~");
if (global.botNamePrefix == "~")
    global.botNamePrefix = "[BOT] ";
global.botMode = string_lower(ini_read_string("Bots", "Mode", "policy"));
global.botEngagesBots = ini_read_real("Bots", "EngagesBots", 0);
global.botNavGenerate = ini_read_real("Bots", "NavGenerate", 1);
ini_close();

menu_create(48, 172, 500, 260, 32, 40, 112, 128);
menumode = true;

menu_background(512, 24, 8, 12, 4);
bgtabs = true;

menu_addedit_boolean("Bots:", "global.botEnabled", '
    gg2_write_ini("Bots", "Enabled", argument0);
');
menu_addedit_num("Fill to players:", "global.botFillToPlayers", '
    gg2_write_ini("Bots", "FillToPlayers", argument0);
', 48);
menu_addedit_num("Max bots:", "global.botMaxBots", '
    gg2_write_ini("Bots", "MaxBots", argument0);
', 48);
menu_addedit_num("Min humans:", "global.botMinHumans", '
    gg2_write_ini("Bots", "MinHumans", argument0);
', 48);
menu_addedit_select("Difficulty:", "global.botDifficulty", '
    gg2_write_ini("Bots", "Difficulty", argument0);
');
menu_add_option(1, "1 (easy)");
menu_add_option(2, "2");
menu_add_option(3, "3");
menu_add_option(4, "4");
menu_add_option(5, "5 (hard)");
// 12: prefix + "Engineer" within MAX_PLAYERNAME_LENGTH. Quoted, or Windows'
// ini reader trims a trailing space.
menu_addedit_text2("Name prefix:", "global.botNamePrefix", '
    var prefix;
    prefix = string_copy(argument0, 1, 12);
    gg2_write_ini("Bots", "NamePrefix", chr(34) + prefix + chr(34));
    return prefix;
');
menu_addedit_select("Fighting:", "global.botMode", '
    gg2_write_ini("Bots", "Mode", argument0);
');
menu_add_option("policy", "Learned policy up close");
menu_add_option("scripted", "Scripted only");
menu_addedit_boolean("Policy against bots:", "global.botEngagesBots", '
    gg2_write_ini("Bots", "EngagesBots", argument0);
');
menu_addedit_boolean("Generate nav for new maps:", "global.botNavGenerate", '
    gg2_write_ini("Bots", "NavGenerate", argument0);
');

menu_addlink("Start Game", '
    start_server();
');

menu_addtablink("Main", '
    instance_create(x,y,HostOptionsController);
    instance_destroy();
');
menu_addtablink("Advanced", '
    instance_create(x,y,AdvHostOptionsController);
    instance_destroy();
');
menu_addtablink("Classlimits", '
    instance_create(x,y,ClasslimitsMenuController);
    instance_destroy();
');
menu_addtablink("Bots", '
    instance_create(x,y,global.botMenuController);
    instance_destroy();
');

menu_addback("Back", '
    instance_create(x,y,MainMenuController);
    instance_destroy();
');
