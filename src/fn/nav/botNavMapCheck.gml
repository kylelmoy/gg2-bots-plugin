// botNavMapCheck(): every 30 Hz tick (hooks/GameServer/end_step.gml). Notices
// a map load and installs that map and area's graph -
// BotPopulationService.MapChanged's nav half.
//
// THE TRIGGER IS THE ROOM, NOT THE MAP NAME. Every map load - rotation, the
// next area of a multi-area map, an admin map change, and a reload of the
// SAME map - goes through serverGotoMap -> room_goto_fix(CustomMapRoom), whose
// creation code ends with instance_create(0, 0, CustomMapO). So a CustomMapO
// with a new instance id means a new room, and only then are
// global.currentMap / currentMapArea / currentMapMD5 read. Watching those
// three instead would fire too early: GameServerBeginStep advances
// currentMapArea at the ROUND END, 300 ticks before the room changes, while
// the old area is still being played.
//
// On a new room: the old graph is freed (global.botNavReady false - bots
// fight but do not walk), occupancy and lanes are reset, and
// global.botNavGeneration is bumped (bots must drop their route state). Then
// <key>.txt is loaded from global.botNavDir if it is there (botNavLoad, which
// bumps the generation again).
//
// If it is not: with global.botNavGenerate on and global.botDir +
// "navgen\gg2-navgen.exe" present, the generator is launched without waiting
// (execute_program(..., false)) - at most once per key per session - and
// <key>.txt is polled every tick until it appears or NAV_GEN_TIMEOUT_MS
// passes. Otherwise, and after a timeout, the file is looked for every
// NAV_RETRY_TICKS, so a graph dropped in by hand is picked up without a
// restart. A file that is there but refused (another version, a bad shape) is
// not retried until the next room.
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
    // Occupancy keys and lane rows only mean anything to one build of a graph.
    botOccupancyReset();
    botLanesFree();
    global.botNavMap = global.currentMap;
    global.botNavArea = global.currentMapArea;
    global.botNavMD5 = global.currentMapMD5;
    key = navGraphKey(global.currentMap, global.currentMapArea, global.currentMapMD5);
    global.botNavKey = key;
    global.botNavGaveUp = false;
    global.botNavRetryAt = 0;
    // A generator still building another key finishes on its own; its files
    // serve the next visit to that map.
    global.botNavGenKey = "";
    global.botNavGeneration += 1;
}

if (global.botNavReady)
    exit;
if (global.botNavGaveUp)
    exit;
key = global.botNavKey;
txt = global.botNavDir + key + ".txt";

// Waiting on gg2-navgen: it writes .dist first and .txt last, each renamed
// into place, so the .txt existing means both are complete.
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

// A built-in map (empty MD5) by name - the generator ships every built-in map;
// a custom map by its PNG, where serverGotoMap found it ("Maps/<name>.png"
// under the working directory).
mapArg = global.botNavMap;
if (global.botNavMD5 != "")
    mapArg = working_directory + "\Maps\" + global.botNavMap + ".png";
// No trailing backslash on --out: `"...\nav\"` would escape the closing quote.
args = '--map "' + mapArg + '" --area ' + string(global.botNavArea) + ' --key ' + key + ' --out "' + global.botDir + 'nav"';
ds_map_add(global.botNavGenLaunched, key, 1);
execute_program(prog, args, false);
global.botNavGenKey = key;
global.botNavGenSince = current_time;
