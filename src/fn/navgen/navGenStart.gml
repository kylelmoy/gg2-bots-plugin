// navGenStart(key, distOnly): begin generating <key>.txt (then <key>.dist)
// for the room being played - NavGenerator.Build and PluginDistFile, run in
// slices by navGenStep. distOnly: the graph is already installed and only the
// tables are missing. False if there is nothing to build from.
//
// Departure: reads the live room, not the map PNG. The walkmask is the
// game's own collision sprite, read through a scale-1 dummy (what the
// reference's navBuildStart did); the entities are the instances the room
// made, already narrowed to the area by basicRoomSetup, as LevelMap.ForArea
// narrows the PNG's.
var key, w, h;
key = argument0;
navGenFree();
global.navGenKey = key;
global.navGenDistOnly = argument1;
global.navGenMs = 0;
global.navGenGraphMs = 0;
global.navGenLongestMs = 0;
global.navGenDistOk = false;
global.navGenStartedAt = current_time;
global.navGenSub = 0;
global.navGenI = 0;

if (argument1)
{
    if (!global.botNavReady)
        return false;
    global.navGenActive = true;
    navGenDistSetup();
    return true;
}

if (!sprite_exists(global.CustomMapCollisionSprite))
    return false;
w = sprite_get_width(global.CustomMapCollisionSprite);
h = sprite_get_height(global.CustomMapCollisionSprite);
if (w < 1 || h < 1)
    return false;
if (!directory_exists(global.botNavDir))
    directory_create(global.botNavDir);
global.navGenW = w;
global.navGenH = h;
global.navGenLastX = w - NAV_BOX_W;
global.navGenLastY = h - NAV_BOX_H;

global.navGenSolid = ds_grid_create(w, h);
global.navGenPlat = ds_grid_create(w, h);
global.navGenLethal = ds_grid_create(w, h);
global.navGenDoor = ds_grid_create(w, h);
global.navGenGate = ds_grid_create(w, h);
ds_grid_clear(global.navGenSolid, 0);
ds_grid_clear(global.navGenPlat, 0);
ds_grid_clear(global.navGenLethal, 0);
// NAV_DOOR_NONE and NAV_GATE_NONE are 0.
ds_grid_clear(global.navGenDoor, NAV_DOOR_NONE);
ds_grid_clear(global.navGenGate, NAV_GATE_NONE);

global.navGenDummy = instance_create(0, 0, global.navGenDummyObj);
global.navGenDummy.sprite_index = global.CustomMapCollisionSprite;
global.navGenDummy.mask_index = global.CustomMapCollisionSprite;
global.navGenDummy.visible = false;

navGenCollect();
global.navGenRunupCache = ds_map_create();
global.navGenRunupSeen = ds_list_create();

global.navGenNodeCount = 0;
global.navGenEdges = ds_grid_create(NAV_EDGE_FIELDS, 4096);
global.navGenEdgeCount = 0;

global.navGenActive = true;
global.navGenStage = NAV_GEN_STAGE_MASK;
global.navGenStageAt[NAV_GEN_STAGE_MASK] = current_time;
return true;
