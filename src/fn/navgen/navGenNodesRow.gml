// navGenNodesRow(cy): NavSurfaces.ExtractNodes for one anchor row - one node
// per maximal run of standable anchors, cut where the support kind (terrain vs
// platform-only), the door code or the gate code changes. Appends to
// global.navGenN*[]; rows are visited in order, so nodes come out sorted by
// row then column as the C#'s do.
//
// standable(c) = no lethal under the footprint, some support under it, and the
// box fits: Ls(c, by) == 0, Hs(c, by) + Ps(c, by) > 0, B(c, cy) == 0.
var cy, by, lastX, hs, ps, ls, bl, door, gate, column, standable, runStart, platformOnly;
var doorCode, gateCode, sameDoor, sameGate, po, n;
cy = argument0;
by = cy + NAV_BOX_H;
if (by >= global.navGenH)
    exit;
lastX = global.navGenLastX;
if (lastX < 0)
    exit;
hs = global.navGenHs;
ps = global.navGenPs;
ls = global.navGenLs;
bl = global.navGenBlocked;
door = global.navGenDoor;
gate = global.navGenGate;
// Nothing to stand on, or nowhere the box fits: the whole row is skipped.
if (ds_grid_get_max(hs, 0, by, lastX, by) == 0 && ds_grid_get_max(ps, 0, by, lastX, by) == 0)
    exit;
if (ds_grid_get_min(bl, 0, cy, lastX, cy) > 0)
    exit;

column = 0;
while (column <= lastX)
{
    standable = (ds_grid_get(ls, column, by) == 0 && ds_grid_get(hs, column, by) + ds_grid_get(ps, column, by) > 0 && ds_grid_get(bl, column, cy) == 0);
    if (!standable)
    {
        column += 1;
        continue;
    }
    runStart = column;
    platformOnly = (ds_grid_get(hs, column, by) == 0 && ds_grid_get(ps, column, by) > 0);
    doorCode = ds_grid_get(door, column, cy);
    gateCode = ds_grid_get(gate, column, cy);
    sameDoor = true;
    sameGate = true;
    po = platformOnly;
    while (column <= lastX && standable && po == platformOnly && sameDoor && sameGate)
    {
        column += 1;
        if (column <= lastX)
        {
            standable = (ds_grid_get(ls, column, by) == 0 && ds_grid_get(hs, column, by) + ds_grid_get(ps, column, by) > 0 && ds_grid_get(bl, column, cy) == 0);
            po = (ds_grid_get(hs, column, by) == 0 && ds_grid_get(ps, column, by) > 0);
            sameDoor = (ds_grid_get(door, column, cy) == doorCode);
            sameGate = (ds_grid_get(gate, column, cy) == gateCode);
        }
        else
        {
            standable = false;
            sameDoor = true;
            sameGate = true;
        }
    }
    n = global.navGenNodeCount;
    global.navGenNY[n] = cy;
    global.navGenNX0[n] = runStart;
    global.navGenNX1[n] = column - 1;
    global.navGenNFlags[n] = platformOnly;
    global.navGenNDoor[n] = doorCode;
    global.navGenNGate[n] = gateCode;
    global.navGenNodeCount = n + 1;
}
