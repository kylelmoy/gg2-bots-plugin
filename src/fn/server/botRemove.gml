// botRemove(player): disconnect a bot the way a client leaves - PLAYER_LEAVE,
// which processClientCommands answers by closing the server's end. The next
// GameServerBeginStep sees the socket error and does the rest (removePlayer,
// ServerPlayerLeave, team balance), exactly as for a person.
botSendByte(argument0, PLAYER_LEAVE, -1);
argument0.botLeaving = true;
