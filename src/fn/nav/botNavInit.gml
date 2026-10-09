// botNavInit(): server start. Creates the nav layer's structures and globals,
// no graph loaded (botNavReady false). Needs botConfigLoad first.
var k;
botNavFree();
global.botNavAlive = true;

// Graph (PORTING.md, "The nav graph in memory").
global.botNavReady = false;
global.botNavNodes = -1;
global.botNavEdges = -1;
global.botNavEdgeStart = -1;
global.botNavRowStart = -1;
global.botNavNodeCount = 0;
global.botNavEdgeCount = 0;
global.botNavMaskW = 0;
global.botNavMaskH = 0;
global.botNavMap = "";
global.botNavArea = 0;
// Bumped when the graph is replaced or dropped; bots drop route state on
// change.
global.botNavGeneration = 0;

// botNavMapCheck state.
global.botNavDir = global.botDir + "nav\";
global.botNavMarker = noone;      // CustomMapO instance the state is for
global.botNavKey = "";            // key for the current room
global.botNavMD5 = "";            // currentMapMD5 at room load
global.botNavGaveUp = false;      // file for this key refused; stop retrying
global.botNavRetryAt = 0;         // botTick of next look for a missing file
global.botNavGenKey = "";         // key gg2-navgen is building
global.botNavGenSince = 0;        // current_time at launch
global.botNavGenLaunched = ds_map_create(); // keys launched this session

// Search scratch; per-node grid sized by navGraphTryLoad.
global.navSearchScratch = -1;
global.navSearchOpen = ds_priority_create();
global.navSearchEntryNode = ds_list_create();
global.navSearchEntryF = ds_list_create();
global.navSearchPops = 0;
global.navSearchQNextRow = 0;

// Distance tables.
global.navDistReady = false;
global.navDistBuffer = -1;
global.navDistNodes = 0;
global.navDistPresent = 0;
global.navDistTableCount = 0;
global.navDistLoadedKey = "";
for (k = 0; k < NAV_DIST_PROFILES; k += 1)
{
    global.navDistByProfile[k] = -1;
    global.navDistKey[k] = -1;
    global.navDistCostAt[k] = 0;
    global.navDistNextAt[k] = 0;
}

// Occupancy (always allocated).
global.botOccupancyRed = ds_map_create();
global.botOccupancyBlue = ds_map_create();

// Lanes.
global.botLanesCost = -1;
global.botLanesCount = 0;
