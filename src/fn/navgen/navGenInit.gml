// navGenInit(): server start (botNavInit). No generation running. The dummy
// object that reads the walkmask is made once per game: GM8 cannot delete an
// object, so a new one per server start would leak.
if (!variable_global_exists("navGenDummyObj"))
    global.navGenDummyObj = object_add();
global.navGenDummy = noone;
global.navGenActive = false;
global.navGenStage = NAV_GEN_STAGE_DONE;
global.navGenKey = "";
global.navGenDistOnly = false;
// Read by navGenUnit whatever the stage, tables-only runs included.
global.navGenNodeCount = 0;
global.navGenEdgeCount = 0;
global.navGenMs = 0;
global.navGenGraphMs = 0;
global.navGenLongestMs = 0;
global.navGenGraphWallMs = 0;
global.navGenDistWallMs = 0;
global.navGenDistOk = false;
global.navGenStartedAt = 0;

global.navGenSolid = -1;
global.navGenPlat = -1;
global.navGenLethal = -1;
global.navGenDoor = -1;
global.navGenGate = -1;
global.navGenHs = -1;
global.navGenPs = -1;
global.navGenLs = -1;
global.navGenBlocked = -1;
global.navGenAir = -1;
global.navGenNodeGrid = -1;
global.navGenEdges = -1;
global.navGenSorted = -1;
global.navGenAdjTo = -1;
global.navGenSortedNodes = -1;
global.navGenCapMemo = -1;
global.navGenRunupCache = -1;
global.navGenRunupSeen = -1;
global.navGenEmitted = -1;
global.navGenDistOpen = -1;
global.navGenDistScratch = -1;
global.navGenDistCost = -1;
global.navGenDistHops = -1;
global.navGenDistTables = -1;
