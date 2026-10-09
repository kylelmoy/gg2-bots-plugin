// botServerStop(): GameServer gone. Free the loopback client sockets and shared
// state.
var i;
global.botRunning = false;
botDebugStop();
if (!variable_global_exists("botJoining"))
    exit;
for (i = 0; i < ds_list_size(global.botJoining); i += 1)
    socket_destroy(ds_list_find_value(global.botJoining, i));
ds_list_destroy(global.botJoining);
ds_list_destroy(global.botJoiningTag);
ds_list_destroy(global.botJoiningName);
ds_list_destroy(global.botJoiningTeam);
ds_list_destroy(global.botJoiningClass);
ds_list_destroy(global.botJoiningSince);
botNavFree();
botPolicyNetFree();
