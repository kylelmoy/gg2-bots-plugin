// navGenDropEdges(i): NavGraphBuilder.DropEdges for node i - holding DOWN
// through a platform-only run from its middle column to the first node below.
var i, row, midX, sourceGate, landed, dropped, arcGate, limit, yy, cellGate, bl, ng, gt;
i = argument0;
if (global.navGenNFlags[i] != 1)
    exit;
bl = global.navGenBlocked;
ng = global.navGenNodeGrid;
gt = global.navGenGate;
row = global.navGenNY[i];
// C# integer division of a non-negative sum.
midX = floor((global.navGenNX0[i] + global.navGenNX1[i]) / 2);
sourceGate = global.navGenNGate[i];
landed = -1;
dropped = 0;
arcGate = NAV_GATE_NONE;
limit = min(global.navGenLastY, row + NAV_MAX_FALL);
for (yy = row + 1; yy <= limit; yy += 1)
{
    if (ds_grid_get(bl, midX, yy) != 0)
        break;
    if (arcGate == NAV_GATE_NONE)
    {
        cellGate = ds_grid_get(gt, midX, yy);
        if (cellGate != NAV_GATE_NONE && cellGate != sourceGate)
            arcGate = cellGate;
    }
    dropped += 1;
    landed = ds_grid_get(ng, midX, yy);
    if (landed >= 0)
        break;
}
if (landed >= 0 && landed != i)
{
    if (arcGate == NAV_GATE_NONE)
        arcGate = global.navGenNGate[landed];
    navGenEdgeAdd(i, landed, NAV_EDGE_DROPTHROUGH, 0, dropped, max(1, dropped), arcGate, -1, -1);
}
