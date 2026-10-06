// botNavInit(): server start. Creates the nav layer's long-lived structures
// and sets every global another module may read, with no graph loaded
// (global.botNavReady false: bots fight but do not walk). The first map is
// picked up by botNavMapCheck on the first tick. Expects botConfigLoad to
// have run (global.botNavGenerate, global.botNavDistancesOn).
var k;
// A server started again without a stop in between must not leak the last one.
botNavFree();
global.botNavAlive = true;

// The graph (PORTING.md, "The nav graph in memory").
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
// Bumped whenever the graph bots hold node and edge indices into is replaced
// or dropped - a map load, including a reload of the same map. A bot whose
// remembered generation differs must drop its route, blacklist and goal.
global.botNavGeneration = 0;

// botNavMapCheck's bookkeeping.
global.botNavDir = global.botDir + "nav\";
global.botNavMarker = noone;      // the CustomMapO instance the current state is for
global.botNavKey = "";            // the key wanted for the room being played
global.botNavMD5 = "";            // currentMapMD5 when that room loaded
global.botNavGaveUp = false;      // a file for this key was refused; stop retrying
global.botNavRetryAt = 0;         // botTick of the next look for a missing file
global.botNavGenKey = "";         // the key a launched gg2-navgen is building
global.botNavGenSince = 0;        // current_time it was launched
global.botNavGenLaunched = ds_map_create(); // keys launched this session, never twice

// The search's shared scratch (one search at a time). The per-node grid is
// sized to each graph by navGraphTryLoad.
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

// Occupancy (always allocated; empty when the feature is off).
global.botOccupancyRed = ds_map_create();
global.botOccupancyBlue = ds_map_create();

// Lanes (none until somebody calls botLanesDerive).
global.botLanesCost = -1;
global.botLanesCount = 0;
