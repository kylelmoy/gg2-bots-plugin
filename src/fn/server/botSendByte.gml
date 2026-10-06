// botSendByte(player, command, payload): a client command from this bot.
// payload -1 sends the command byte alone (DROP_INTEL, TOGGLE_ZOOM,
// BUILD_SENTRY, OMNOMNOMNOM); otherwise one payload byte follows
// (PLAYER_CHANGETEAM, PLAYER_CHANGECLASS, CHAT_BUBBLE). See
// GameServerDefineCommands.gml for which is which.
var cs;
cs = argument0.botSock;
write_ubyte(cs, argument1);
if (argument2 >= 0)
    write_ubyte(cs, argument2);
socket_send(cs);
