// navGraphFree(): drop the graph, its indices and search scratch; botNavReady
// false. Not in the C#. Distance tables are navDistFree's.
global.botNavReady = false;
if (global.botNavNodes >= 0)
    ds_grid_destroy(global.botNavNodes);
if (global.botNavEdges >= 0)
    ds_grid_destroy(global.botNavEdges);
if (global.botNavEdgeStart >= 0)
    ds_grid_destroy(global.botNavEdgeStart);
if (global.botNavRowStart >= 0)
    ds_grid_destroy(global.botNavRowStart);
if (global.navSearchScratch >= 0)
    ds_grid_destroy(global.navSearchScratch);
global.botNavNodes = -1;
global.botNavEdges = -1;
global.botNavEdgeStart = -1;
global.botNavRowStart = -1;
global.navSearchScratch = -1;
global.botNavNodeCount = 0;
global.botNavEdgeCount = 0;
global.botNavMaskW = 0;
global.botNavMaskH = 0;
