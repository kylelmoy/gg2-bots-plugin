// botServerStart(): run as the GameServer on its first End Step (bots.gml).
// GameServerCreate may fail to listen or self-connect and still finish, so
// check.
if (global.tcpListener < 0)
    exit;
if (socket_has_error(global.tcpListener))
    exit;

botConfigLoad();

global.botTick = 0;
global.botNextJoinTag = 1;
global.botJoining = ds_list_create();      // sockets mid-handshake
global.botJoiningTag = ds_list_create();   // unique join name
global.botJoiningName = ds_list_create();  // final name
global.botJoiningTeam = ds_list_create();
global.botJoiningClass = ds_list_create();
global.botJoiningSince = ds_list_create(); // current_time at start
global.botMapKey = "";

// Existing Players (the host) are human; the Player Create hook flags later
// ones.
with (Player)
    if (!variable_local_exists("botIsBot"))
        botIsBot = false;

botNavInit();
botBrainInit();
botStatsReset();
global.botRunning = true;
