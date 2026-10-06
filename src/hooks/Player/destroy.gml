// The game destroys the server's end of the socket (Player Destroy). The bot's
// own end, and whatever the bot layer holds for it, are ours.
if (botIsBot)
{
    botDetach(id);
    socket_destroy(botSock);
}
