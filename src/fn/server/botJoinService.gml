// botJoinService(): finish the handshakes botJoinStart began.
//
// Run after GameServerEndStep, which is where JoiningPlayer instances are
// serviced and a finished one becomes a Player - so a bot that joined this
// frame is found this frame, and its rename goes out in the same broadcast as
// its PLAYER_JOIN, after it. No client ever draws the tag.
var i, cs, tag, found, slot;
for (i = 0; i < ds_list_size(global.botJoining); i += 1)
{
    cs = ds_list_find_value(global.botJoining, i);
    tag = ds_list_find_value(global.botJoiningTag, i);
    tcp_receive_available(cs); // whatever the server says to a joining client, unread

    found = noone;
    with (Player)
        if (name == tag)
            found = id;

    if (found == noone)
    {
        // A refused join (server full, wrong password) closes the connection.
        if (!socket_has_error(cs) and current_time - ds_list_find_value(global.botJoiningSince, i) < 10000)
            continue;
        socket_destroy(cs);
    }
    else
    {
        slot = ds_list_find_index(global.players, found);
        with (found)
        {
            botIsBot = true;
            botSock = cs;
            name = ds_list_find_value(global.botJoiningName, i);
            botWantTeam = ds_list_find_value(global.botJoiningTeam, i);
            botWantClass = ds_list_find_value(global.botJoiningClass, i);
            botWasAlive = false;
            botJoinedTick = global.botTick;
            botLastTeamAsk = global.botTick;
        }
        // processClientCommands' PLAYER_CHANGENAME, minus the socket round trip,
        // which would rate-limit a bot's class rename a second later.
        write_ubyte(global.sendBuffer, PLAYER_CHANGENAME);
        write_ubyte(global.sendBuffer, slot);
        write_ubyte(global.sendBuffer, string_length(found.name));
        write_string(global.sendBuffer, found.name);

        // Team and class are asked for the way a client asks.
        botSendByte(found, PLAYER_CHANGECLASS, found.botWantClass);
        botSendByte(found, PLAYER_CHANGETEAM, found.botWantTeam);
        botAttach(found);
    }
    ds_list_delete(global.botJoining, i);
    ds_list_delete(global.botJoiningTag, i);
    ds_list_delete(global.botJoiningName, i);
    ds_list_delete(global.botJoiningTeam, i);
    ds_list_delete(global.botJoiningClass, i);
    ds_list_delete(global.botJoiningSince, i);
    i -= 1;
}
