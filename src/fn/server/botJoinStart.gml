// botJoinStart(team, class, name): connect a bot as a loopback client of this
// server. Sends the whole handshake at once under a unique tag; botJoinService
// finds and renames it.
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
