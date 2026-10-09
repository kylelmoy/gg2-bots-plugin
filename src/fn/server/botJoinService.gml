// botJoinService(): finish botJoinStart's handshakes. Runs after
// GameServerEndStep turns joiners into Players, so the rename follows
// PLAYER_JOIN in the same broadcast.
var i, cs, tag, found, slot;
for (i = 0; i < ds_list_size(global.botJoining); i += 1)
{
    cs = ds_list_find_value(global.botJoining, i);
    tag = ds_list_find_value(global.botJoiningTag, i);
    tcp_receive_available(cs); // drain, never read

    found = noone;
    with (Player)
        if (name == tag)
            found = id;

    if (found == noone)
    {
        // Refused joins error the socket; give up after 10 s too.
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
        // PLAYER_CHANGENAME written directly; via the socket it would
        // rate-limit the class rename.
        write_ubyte(global.sendBuffer, PLAYER_CHANGENAME);
        write_ubyte(global.sendBuffer, slot);
        write_ubyte(global.sendBuffer, string_length(found.name));
        write_string(global.sendBuffer, found.name);

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
