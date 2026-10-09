// navGenCeiling(col, row, dir, colLimit, needRise): NavArcModel.Ceiling - how
// high a body jumping from (col, row) toward dir can rise before the map stops
// it, in px. The straight-up scan (memoised) first; only if that does not give
// needRise, the scan over the corridor the arc could drift into, one column a
// row toward the target and bounded by colLimit. Airborne, the body is a row
// taller than standing, so each scanned row also needs the row above it free.
var col, row, dir, colLimit, needRise, straight, cap, r, scanRow, lo, hi, open, xx, air, w, memo;
col = argument0;
row = argument1;
dir = argument2;
colLimit = argument3;
needRise = argument4;
air = global.navGenAir;
memo = global.navGenCapMemo;

straight = ds_grid_get(memo, col, row);
if (straight < 0)
{
    straight = global.navGenApex;
    for (r = 1; r <= global.navGenMaxRows; r += 1)
    {
        scanRow = row - r;
        if (scanRow < 0)
            break;
        open = (ds_grid_get(air, col, scanRow) == 0);
        if (!open)
        {
            straight = (r - 1) * NAV_CELL_SIZE;
            break;
        }
    }
    ds_grid_set(memo, col, row, straight);
}
if (straight >= needRise)
    return straight;

w = global.navGenW;
cap = global.navGenApex;
for (r = 1; r <= global.navGenMaxRows; r += 1)
{
    scanRow = row - r;
    // Above the top of the walkmask is open sky.
    if (scanRow < 0)
        break;
    if (dir < 0)
    {
        lo = max(col - r, colLimit);
        hi = col;
    }
    else
    {
        lo = col;
        hi = min(col + r, colLimit);
    }
    lo = max(0, lo);
    hi = min(w - 1, hi);
    open = false;
    for (xx = lo; xx <= hi; xx += 1)
    {
        if (ds_grid_get(air, xx, scanRow) == 0)
        {
            open = true;
            break;
        }
    }
    if (!open)
    {
        cap = (r - 1) * NAV_CELL_SIZE;
        break;
    }
}
return cap;
