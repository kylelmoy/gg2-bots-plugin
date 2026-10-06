// botJoinStart(team, class, name): connect one bot to this server as a client.
//
// A bot is a real client of its own server, on a loopback connection - the
// same thing the game does for the host's own player (GameServerCreate). So it
// joins through the ordinary handshake (serviceJoiningPlayer), owns a real
// socket that every guard in the game already understands, and every command
// it gives later (team, class, zoom, build, eat, drop) is a real client
// command handled by processClientCommands. Nothing in the game is patched.
//
// The whole handshake is written at once: the server reads it a field at a
// time as its state machine gets to each one. The bot joins under a unique
// tag so botJoinService can find the Player it becomes, and is renamed then.
var cs, tag, i;
cs = tcp_connect("127.0.0.1", global.hostingPort);
if (socket_has_error(cs))
{
    socket_destroy(cs);
    exit;
}
tag = "~bot" + string(global.botNextJoinTag);
global.botNextJoinTag += 1;

write_ubyte(cs, HELLO);
buffer_set_readpos(global.protocolUuid, 0);
for (i = 0; i < 4; i += 1)
    write_uint(cs, read_uint(global.protocolUuid));
if (global.serverPassword != "")
{
    write_ubyte(cs, string_length(global.serverPassword));
    write_string(cs, global.serverPassword);
}
write_ubyte(cs, RESERVE_SLOT);
write_ubyte(cs, string_length(tag));
write_string(cs, tag);
write_ubyte(cs, PLAYER_JOIN);
socket_send(cs);

ds_list_add(global.botJoining, cs);
ds_list_add(global.botJoiningTag, tag);
ds_list_add(global.botJoiningName, argument2);
ds_list_add(global.botJoiningTeam, argument0);
ds_list_add(global.botJoiningClass, argument1);
ds_list_add(global.botJoiningSince, current_time);
