// botNavMapCheck(): every tick. On a new room, installs that map+area's graph -
// MapChanged's nav half. A new CustomMapO instance id marks a new room (map
// globals change at round end, before the room does).
// No <key>.txt: generate it in GML (navGen*, once per key per session, if
// NavGenerate is on), a slice a tick, then its distance tables the same way;
// else look every NAV_RETRY_TICKS. A refused file is not retried until the
// next room. A graph whose <key>.dist is missing gets its tables generated.
var marker, key, txt, ok;
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
    navGenFree();
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
    global.botNavGeneration += 1;
}
key = global.botNavKey;

if (global.navGenActive)
{
    navGenStep(NAV_GEN_BUDGET_MS);
    if (global.navGenStage == NAV_GEN_STAGE_GRAPH_DONE)
    {
        ok = botNavLoad();
        if (!ok)
        {
            global.botNavGaveUp = true;
            navGenFree();
        }
        else if (global.botNavDistancesOn && !global.navDistReady)
            navGenDistSetup();
        else
            navGenFree();
    }
    else if (global.navGenStage == NAV_GEN_STAGE_DONE)
    {
        if (global.navGenDistOk && global.botNavReady)
        {
            navDistLoad(global.botNavDir + key + ".dist");
            global.navDistLoadedKey = key + "/" + string(global.botNavNodeCount) + "/" + string(global.botNavEdgeCount);
        }
        else if (!global.botNavReady)
            global.botNavGaveUp = true;
        navGenFree();
    }
    exit;
}

if (global.botNavReady)
{
    // Loaded from a file whose tables are missing (or stale): make them.
    if (global.botNavDistancesOn && global.botNavGenerate && !global.navDistReady)
    {
        if (!ds_map_exists(global.botNavGenLaunched, key + ".dist"))
        {
            ds_map_add(global.botNavGenLaunched, key + ".dist", 1);
            navGenStart(key, true);
        }
    }
    exit;
}
if (global.botNavGaveUp)
    exit;
if (global.botTick < global.botNavRetryAt)
    exit;
global.botNavRetryAt = global.botTick + NAV_RETRY_TICKS;

txt = global.botNavDir + key + ".txt";
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
ds_map_add(global.botNavGenLaunched, key, 1);
ok = navGenStart(key, false);
if (!ok)
    global.botNavGaveUp = true;
