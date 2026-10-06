// botNavFree(): server stop. Frees everything botNavInit and the loads made.
// A generator still running is left to finish on its own; it only writes
// files.
if (!variable_global_exists("botNavAlive"))
    exit;
if (!global.botNavAlive)
    exit;
global.botNavAlive = false;
navGraphFree();
navDistFree();
botLanesFree();
global.navDistLoadedKey = "";
ds_priority_destroy(global.navSearchOpen);
ds_list_destroy(global.navSearchEntryNode);
ds_list_destroy(global.navSearchEntryF);
ds_map_destroy(global.botOccupancyRed);
ds_map_destroy(global.botOccupancyBlue);
ds_map_destroy(global.botNavGenLaunched);
global.navSearchOpen = -1;
global.navSearchEntryNode = -1;
global.navSearchEntryF = -1;
global.botOccupancyRed = -1;
global.botOccupancyBlue = -1;
global.botNavMarker = noone;
global.botNavKey = "";
global.botNavGenKey = "";
global.botNavGeneration += 1;
