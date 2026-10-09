// botNavMapCheck(): every tick. On a new room, installs that map+area's graph -
// MapChanged's nav half. A new CustomMapO instance id marks a new room (map
// globals change at round end, before the room does).
// No <key>.txt: launch gg2-navgen once per key (if enabled and present) and
// poll until NAV_GEN_TIMEOUT_MS, else look every NAV_RETRY_TICKS. A refused
// file is not retried until the next room.
var marker, key, txt, ok, prog, mapArg, args;
if (!variable_global_exists("botNavAlive"))
    exit;
if (!global.botNavAlive)
    exit;
if (instance_number(CustomMapO) < 1)
    exit;
marker = instance_find(CustomMapO, 0);
if (marker != global.botNavMarker)
{
    global.botNavMarker = marker;
    navGraphFree();
    botOccupancyReset();
    botLanesFree();
    global.botNavMap = global.currentMap;
    global.botNavArea = global.currentMapArea;
    global.botNavMD5 = global.currentMapMD5;
    key = navGraphKey(global.currentMap, global.currentMapArea, global.currentMapMD5);
    global.botNavKey = key;
    global.botNavGaveUp = false;
    global.botNavRetryAt = 0;
    global.botNavGenKey = "";
    global.botNavGeneration += 1;
}

if (global.botNavReady)
    exit;
if (global.botNavGaveUp)
    exit;
key = global.botNavKey;
txt = global.botNavDir + key + ".txt";

// gg2-navgen writes .txt last, so its existence means both files are complete.
if (global.botNavGenKey == key)
{
    if (file_exists(txt))
    {
        global.botNavGenKey = "";
        ok = botNavLoad();
        if (!ok)
            global.botNavGaveUp = true;
        exit;
    }
    if (current_time - global.botNavGenSince > NAV_GEN_TIMEOUT_MS)
    {
        global.botNavGenKey = "";
        global.botNavRetryAt = global.botTick + NAV_RETRY_TICKS;
    }
    exit;
}

if (global.botTick < global.botNavRetryAt)
    exit;
global.botNavRetryAt = global.botTick + NAV_RETRY_TICKS;

if (file_exists(txt))
{
    ok = botNavLoad();
    if (!ok)
        global.botNavGaveUp = true;
    exit;
}

if (!global.botNavGenerate)
    exit;
if (ds_map_exists(global.botNavGenLaunched, key))
    exit;
prog = global.botDir + "navgen\gg2-navgen.exe";
if (!file_exists(prog))
    exit;

// Built-in map (empty MD5) by name; custom map by its PNG path.
mapArg = global.botNavMap;
if (global.botNavMD5 != "")
    mapArg = working_directory + "\Maps\" + global.botNavMap + ".png";
// No trailing backslash on --out: it would escape the closing quote.
args = '--map "' + mapArg + '" --area ' + string(global.botNavArea) + ' --key ' + key + ' --out "' + global.botDir + 'nav"';
ds_map_add(global.botNavGenLaunched, key, 1);
execute_program(prog, args, false);
global.botNavGenKey = key;
global.botNavGenSince = current_time;
