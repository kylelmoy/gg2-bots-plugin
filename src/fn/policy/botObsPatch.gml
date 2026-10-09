// botObsPatch(char): ObservationWriter.WriteGeometry's walkmask patch - rows
// 140..203, 8 x 8 samples 16 px apart, row-major, 1 where solid.
// Rectangles prune empty patch/rows first; padded 1 px so they only
// over-report.
var ch, g, rx, ry, x0, x1, y0, y1, row, col, px, py;
ch = argument0;
g = global.botObsGrid;
rx = round(ch.x);
ry = round(ch.y);
x0 = rx - (BOT_OBS_PATCH_SIDE / 2) * BOT_OBS_PATCH_CELL;
x1 = rx + (BOT_OBS_PATCH_SIDE / 2 - 1) * BOT_OBS_PATCH_CELL;
y0 = ry - (BOT_OBS_PATCH_SIDE / 2) * BOT_OBS_PATCH_CELL;
y1 = ry + (BOT_OBS_PATCH_SIDE / 2 - 1) * BOT_OBS_PATCH_CELL;
if (collision_rectangle(x0 - 1, y0 - 1, x1 + 1, y1 + 1, CollisionMapO, true, false) == noone)
    exit;
for (row = 0; row < BOT_OBS_PATCH_SIDE; row += 1)
{
    py = ry + (row - BOT_OBS_PATCH_SIDE / 2) * BOT_OBS_PATCH_CELL;
    if (collision_rectangle(x0 - 1, py - 1, x1 + 1, py + 1, CollisionMapO, true, false) == noone)
        continue;
    for (col = 0; col < BOT_OBS_PATCH_SIDE; col += 1)
    {
        px = rx + (col - BOT_OBS_PATCH_SIDE / 2) * BOT_OBS_PATCH_CELL;
        if (collision_point(px, py, CollisionMapO, true, false) != noone)
            ds_grid_set(g, 0, BOT_OBS_AT_PATCH + row * BOT_OBS_PATCH_SIDE + col, 1);
    }
}
