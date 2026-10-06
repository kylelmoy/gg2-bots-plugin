// gg2-bots: server-side bots for Gang Garrison 2, as a local plugin.
//
// The game runs every Plugins/*.gml at startup (loadplugins.gml), on clients
// and hosts alike, so this file does as little as possible: it remembers where
// its files are and hooks GameServer's Create event. Only when this game starts
// hosting does it compile the bot layer - every function and hook listed in
// bots/code/manifest.txt - and start it. A client that never hosts pays for
// one object_event_add.
//
// Not transpiled by tools/botc.js: this is the code that makes transpiled code
// callable, so it calls nothing through it except the two entry points, by hand.

global.botDir = directory + "bots\";
global.botLoaded = false;

// string botReadFile(path): the whole file, lines joined with CRLF
global.botReadFile = '
    var f, s;
    s = "";
    f = file_text_open_read(argument0);
    while (!file_text_eof(f))
    {
        s += file_text_read_string(f) + chr(13) + chr(10);
        file_text_readln(f);
    }
    file_text_close(f);
    return s;
';

// botLoad(): compile every function and attach every hook, once per game.
global.botLoad = '
    var f, line, kind, rest, name, path, obj, evtype, evnumb, sp, count;
    if (!file_exists(global.botDir + "code\manifest.txt"))
    {
        show_message("gg2-bots: " + global.botDir + "code\manifest.txt is missing; bots are disabled.");
        return false;
    }
    count = 0;
    f = file_text_open_read(global.botDir + "code\manifest.txt");
    while (!file_text_eof(f))
    {
        line = file_text_read_string(f);
        file_text_readln(f);
        if (line == "")
            continue;
        sp = string_pos(" ", line);
        kind = string_copy(line, 1, sp - 1);
        rest = string_delete(line, 1, sp);
        if (kind == "fn")
        {
            sp = string_pos(" ", rest);
            name = string_copy(rest, 1, sp - 1);
            path = string_delete(rest, 1, sp);
            obj = object_add();
            object_event_add(obj, ev_other, ev_user0, execute_string(global.botReadFile, global.botDir + path));
            variable_global_set("botF_" + name, obj);
        }
        else if (kind == "hook")
        {
            sp = string_pos(" ", rest);
            name = string_copy(rest, 1, sp - 1);
            rest = string_delete(rest, 1, sp);
            sp = string_pos(" ", rest);
            evtype = execute_string("return " + string_copy(rest, 1, sp - 1) + ";");
            rest = string_delete(rest, 1, sp);
            sp = string_pos(" ", rest);
            evnumb = execute_string("return " + string_copy(rest, 1, sp - 1) + ";");
            path = string_delete(rest, 1, sp);
            obj = execute_string("return " + name + ";");
            object_event_add(obj, evtype, evnumb, execute_string(global.botReadFile, global.botDir + path));
        }
        count += 1;
    }
    file_text_close(f);
    global.botLoaded = true;
    return true;
';

// Appended to GameServer Create, after GameServerCreate has run. That script
// destroys the instance and exits when it cannot listen, and the rest of the
// event still runs, so botServerStart checks for that itself.
object_event_add(GameServer, ev_create, 0, '
    if (!global.botLoaded)
        execute_string(global.botLoad);
    if (global.botLoaded)
        event_perform_object(global.botF_botServerStart, ev_other, ev_user0);
');

object_event_add(GameServer, ev_destroy, 0, '
    if (global.botLoaded)
        event_perform_object(global.botF_botServerStop, ev_other, ev_user0);
');
