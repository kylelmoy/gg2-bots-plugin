// botRemove(player): send PLAYER_LEAVE as a client would; the game removes the
// Player when GameServerBeginStep sees the closed socket.
botSendByte(argument0, PLAYER_LEAVE, -1);
argument0.botLeaving = true;
