// botSendByte(player, command, payload): send a client command from this bot.
// payload -1 sends the command byte alone; otherwise one payload byte follows.
var cs;
cs = argument0.botSock;
write_ubyte(cs, argument1);
if (argument2 >= 0)
    write_ubyte(cs, argument2);
socket_send(cs);
