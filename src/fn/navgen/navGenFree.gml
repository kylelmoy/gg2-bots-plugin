// navGenFree(): stop any generation and free what it holds. Safe to call
// with nothing running, and twice.
var t;
if (!variable_global_exists("navGenActive"))
    exit;
global.navGenActive = false;
global.navGenStage = NAV_GEN_STAGE_DONE;
// with() skips an instance the room change already destroyed.
with (global.navGenDummy)
    instance_destroy();
global.navGenDummy = noone;

if (global.navGenSolid >= 0)
    ds_grid_destroy(global.navGenSolid);
if (global.navGenPlat >= 0)
    ds_grid_destroy(global.navGenPlat);
if (global.navGenLethal >= 0)
    ds_grid_destroy(global.navGenLethal);
if (global.navGenDoor >= 0)
    ds_grid_destroy(global.navGenDoor);
if (global.navGenGate >= 0)
    ds_grid_destroy(global.navGenGate);
if (global.navGenHs >= 0)
    ds_grid_destroy(global.navGenHs);
if (global.navGenPs >= 0)
    ds_grid_destroy(global.navGenPs);
if (global.navGenLs >= 0)
    ds_grid_destroy(global.navGenLs);
if (global.navGenBlocked >= 0)
    ds_grid_destroy(global.navGenBlocked);
if (global.navGenAir >= 0)
    ds_grid_destroy(global.navGenAir);
if (global.navGenNodeGrid >= 0)
    ds_grid_destroy(global.navGenNodeGrid);
if (global.navGenEdges >= 0)
    ds_grid_destroy(global.navGenEdges);
if (global.navGenSorted >= 0)
    ds_grid_destroy(global.navGenSorted);
if (global.navGenAdjTo >= 0)
    ds_grid_destroy(global.navGenAdjTo);
if (global.navGenSortedNodes >= 0)
    ds_grid_destroy(global.navGenSortedNodes);
if (global.navGenCapMemo >= 0)
    ds_grid_destroy(global.navGenCapMemo);
if (global.navGenRunupCache >= 0)
    ds_map_destroy(global.navGenRunupCache);
if (global.navGenRunupSeen >= 0)
    ds_list_destroy(global.navGenRunupSeen);
if (global.navGenEmitted >= 0)
    ds_map_destroy(global.navGenEmitted);
if (global.navGenDistOpen >= 0)
    ds_priority_destroy(global.navGenDistOpen);
if (global.navGenDistScratch >= 0)
    ds_grid_destroy(global.navGenDistScratch);
if (global.navGenDistCost >= 0)
    buffer_destroy(global.navGenDistCost);
if (global.navGenDistHops >= 0)
    buffer_destroy(global.navGenDistHops);
if (global.navGenDistTables >= 0)
{
    for (t = 0; t < ds_list_size(global.navGenDistTables); t += 1)
        buffer_destroy(ds_list_find_value(global.navGenDistTables, t));
    ds_list_destroy(global.navGenDistTables);
}

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
