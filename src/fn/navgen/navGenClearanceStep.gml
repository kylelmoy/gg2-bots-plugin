// navGenClearanceStep(sub): one native region operation of NavSurfaces.Clearance
// and of the support windows ExtractNodes slides. Returns the next sub, or -1
// when done. Each step is one whole-grid pass (~15 ms on the largest map).
//
// Departure: the C#'s sliding counts become shifted grid additions.
//   Hs(cx, cy) = solid cells in [cx, cx + BOX_W) on row cy (horizontal count;
//                read at cy + BOX_H it is ExtractNodes' `support`)
//   Ps, Ls     = the same window over platform and lethal cells
//   B(cx, cy)  = Hs summed over rows [cy, cy + BOX_H), and 1 past lastX/lastY
// so a cell is free (the C#'s free == 1) exactly where B == 0.
//   Air        = B plus B one row up (see the last step)
var sub, w, h, k;
sub = argument0;
w = global.navGenW;
h = global.navGenH;

if (sub == 0)
{
    global.navGenHs = ds_grid_create(w, h);
    global.navGenPs = ds_grid_create(w, h);
    global.navGenLs = ds_grid_create(w, h);
    ds_grid_clear(global.navGenHs, 0);
    ds_grid_clear(global.navGenPs, 0);
    ds_grid_clear(global.navGenLs, 0);
    return 1;
}
if (sub <= 12)
{
    k = (sub - 1) mod 4;
    if (k <= w - 1)
    {
        if (sub <= 4)
            ds_grid_add_grid_region(global.navGenHs, global.navGenSolid, k, 0, w - 1, h - 1, 0, 0);
        else if (sub <= 8)
            ds_grid_add_grid_region(global.navGenPs, global.navGenPlat, k, 0, w - 1, h - 1, 0, 0);
        else
            ds_grid_add_grid_region(global.navGenLs, global.navGenLethal, k, 0, w - 1, h - 1, 0, 0);
    }
    return sub + 1;
}
if (sub == 13)
{
    ds_grid_destroy(global.navGenSolid);
    ds_grid_destroy(global.navGenPlat);
    ds_grid_destroy(global.navGenLethal);
    global.navGenSolid = -1;
    global.navGenPlat = -1;
    global.navGenLethal = -1;
    global.navGenBlocked = ds_grid_create(w, h);
    ds_grid_clear(global.navGenBlocked, 0);
    return 14;
}
if (sub <= 19)
{
    k = sub - 14;
    if (k <= h - 1)
        ds_grid_add_grid_region(global.navGenBlocked, global.navGenHs, 0, k, w - 1, h - 1, 0, 0);
    return sub + 1;
}

if (sub == 20)
{
    // Only anchors at cx <= lastX, cy <= lastY can hold the box.
    if (w < NAV_BOX_W || h < NAV_BOX_H)
        ds_grid_clear(global.navGenBlocked, 1);
    else
    {
        if (global.navGenLastX + 1 <= w - 1)
            ds_grid_set_region(global.navGenBlocked, global.navGenLastX + 1, 0, w - 1, h - 1, 1);
        if (global.navGenLastY + 1 <= h - 1)
            ds_grid_set_region(global.navGenBlocked, 0, global.navGenLastY + 1, w - 1, h - 1, 1);
    }
    return 21;
}

// Air(cx, cy) = B(cx, cy) + B(cx, cy - 1): an airborne body is a row taller
// than a standing one, so the arc code's "this cell and the one above are
// free" is one read, Air == 0.
global.navGenAir = ds_grid_create(w, h);
ds_grid_copy(global.navGenAir, global.navGenBlocked);
if (h >= 2)
    ds_grid_add_grid_region(global.navGenAir, global.navGenBlocked, 0, 0, w - 1, h - 2, 0, 1);
return -1;
