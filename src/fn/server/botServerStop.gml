// botServerStop(): the GameServer is being destroyed (the host left).
// Players are destroyed with their own sockets by the game; what is ours is
// the client end of every loopback connection and the shared structures.
var i;
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
