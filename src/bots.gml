// gg2-bots: server-side bots for Gang Garrison 2, as a local plugin. Runs on
// every client and host, so it only adds the host menu's Bots tab and hooks
// GameServer's End Step; the bot layer
// (bots/code/manifest.txt) is compiled and started on hosting. Not transpiled:
// calls transpiled code only through its two entry points.

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

// The "Bots" tab of the host options menu, a MenuController like the stock
// tabs; its Create is bots/menu.gml. The stock tabs' Creates get a link to it.
global.botMenuController = object_add();
object_set_parent(global.botMenuController, MenuController);
object_event_add(global.botMenuController, ev_create, 0, execute_string(global.botReadFile, global.botDir + "menu.gml"));
object_event_add(global.botMenuController, ev_step, ev_step_normal, '
    if (!instance_exists(HostWarningsController))
        instance_create(0, 0, HostWarningsController);
    event_inherited();
');
object_event_add(global.botMenuController, ev_destroy, 0, '
    with (HostWarningsController)
        instance_destroy();
');
object_event_add(HostOptionsController, ev_create, 0, '
    menu_addtablink("Bots", "instance_create(x,y,global.botMenuController); instance_destroy();");
');
object_event_add(AdvHostOptionsController, ev_create, 0, '
    menu_addtablink("Bots", "instance_create(x,y,global.botMenuController); instance_destroy();");
');
object_event_add(ClasslimitsMenuController, ev_create, 0, '
    menu_addtablink("Bots", "instance_create(x,y,global.botMenuController); instance_destroy();");
');

// Start on each GameServer's first End Step, not Create: Create ends in
// room_goto, and GM8 skips the rest of an event after room_goto. botStarted is
// per instance.
object_event_add(GameServer, ev_step, ev_step_end, '
    if (!variable_local_exists("botStarted"))
    {
        botStarted = true;
        if (!global.botLoaded)
            execute_string(global.botLoad);
        if (global.botLoaded)
            event_perform_object(global.botF_botServerStart, ev_other, ev_user0);
    }
');

// Stop is noticed from AudioControl (persistent): GameServer's Destroy also
// ends in room_goto.
global.botRunning = false;
object_event_add(AudioControl, ev_step, ev_step_end, '
    if (global.botRunning)
        if (!instance_exists(GameServer))
            event_perform_object(global.botF_botServerStop, ev_other, ev_user0);
');
