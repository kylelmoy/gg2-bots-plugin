// navGenNodesFinish(): NavSurfaces.NodeGrid and RowIndex, then drop the grids
// only extraction needed. global.navGenNodeGrid(cx, cy) is the node anchored
// there or -1; global.navGenRowStart[row] (rows 0..H+1) the first node on a
// row or -1, filled backwards so the lowest index wins.
var i, n, w, h;
n = global.navGenNodeCount;
w = global.navGenW;
h = global.navGenH;
global.navGenNodeGrid = ds_grid_create(w, h);
ds_grid_clear(global.navGenNodeGrid, -1);
for (i = 0; i < n; i += 1)
    ds_grid_set_region(global.navGenNodeGrid, global.navGenNX0[i], global.navGenNY[i], global.navGenNX1[i], global.navGenNY[i], i);
for (i = 0; i < h + 2; i += 1)
    global.navGenRowStart[i] = -1;
for (i = n - 1; i >= 0; i -= 1)
    global.navGenRowStart[global.navGenNY[i]] = i;
// Sentinels so `j < n && NY[j] == row` loops can read NY[n] safely.
global.navGenNY[n] = -1;

ds_grid_destroy(global.navGenHs);
ds_grid_destroy(global.navGenPs);
ds_grid_destroy(global.navGenLs);
ds_grid_destroy(global.navGenDoor);
global.navGenHs = -1;
global.navGenPs = -1;
global.navGenLs = -1;
global.navGenDoor = -1;
