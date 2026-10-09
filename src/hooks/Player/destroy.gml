// The game frees the server's socket end; free the bot's end and its state.
if (botIsBot)
{
    botDetach(id);
    socket_destroy(botSock);
}
