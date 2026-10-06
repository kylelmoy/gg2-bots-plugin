// botServerStart(): a GameServer has just been created. Called by bots.gml,
// as the GameServer instance, after GameServerCreate has run.
//
// GameServerCreate destroys itself and exits when it cannot listen or cannot
// connect to itself; the rest of the Create event still runs, so check.
if (global.tcpListener < 0)
    exit;
if (socket_has_error(global.tcpListener))
    exit;

botConfigLoad();

global.botTick = 0;
global.botNextJoinTag = 1;
global.botJoining = ds_list_create();      // client sockets mid-handshake
global.botJoiningTag = ds_list_create();   // the unique name each is joining under
global.botJoiningName = ds_list_create();  // the name it gets once joined
global.botJoiningTeam = ds_list_create();
global.botJoiningClass = ds_list_create();
global.botJoiningSince = ds_list_create(); // current_time it started
global.botMapKey = "";

// Every Player that exists before the plugin started (the host's own) is a
// human. Players created later get the flag from the Player Create hook.
with (Player)
    if (!variable_local_exists("botIsBot"))
        botIsBot = false;

botNavInit();
botBrainInit();
botStatsReset();
