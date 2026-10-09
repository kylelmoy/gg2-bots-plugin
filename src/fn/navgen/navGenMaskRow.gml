// navGenMaskRow(row): one row of the walkmask into global.navGenSolid
// (Walkmask.ToCellBytes). A cell is solid where the map's collision sprite,
// at scale 1 through the dummy, has a pixel. An empty row costs one test.
var row, w, d, cx;
row = argument0;
w = global.navGenW;
d = global.navGenDummy;
if (collision_rectangle(0, row, w - 1, row, d, true, false) < 0)
    exit;
for (cx = 0; cx < w; cx += 1)
    if (collision_point(cx, row, d, true, false) >= 0)
        ds_grid_set(global.navGenSolid, cx, row, 1);
