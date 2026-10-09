// navGenFallEdges(i): NavGraphBuilder.FallEdges for node i - walking off
// either end of the run and falling to the first node below in that column.
// The swept cells' gates are read so a drop past a spawn gate is offered only
// to whoever may pass it; the takeoff column is stored (which END a fall leaves
// from is not recoverable from the two nodes).
var i, w, row, sourceGate, side, edgeCol, landed, dropped, arcGate, limit, yy, cellGate, bl, ng, gt;
i = argument0;
w = global.navGenW;
bl = global.navGenBlocked;
ng = global.navGenNodeGrid;
gt = global.navGenGate;
row = global.navGenNY[i];
sourceGate = global.navGenNGate[i];
for (side = 0; side < 2; side += 1)
{
    if (side == 0)
        edgeCol = global.navGenNX0[i] - 1;
    else
        edgeCol = global.navGenNX1[i] + 1;
    if (edgeCol < 0 || edgeCol > global.navGenLastX)
        continue;
    if (ds_grid_get(bl, edgeCol, row) != 0)
        continue;
    if (ds_grid_get(ng, edgeCol, row) >= 0)
        continue;
    landed = -1;
    dropped = 0;
    arcGate = NAV_GATE_NONE;
    limit = min(global.navGenLastY, row + NAV_MAX_FALL);
    for (yy = row + 1; yy <= limit; yy += 1)
    {
        if (ds_grid_get(bl, edgeCol, yy) != 0)
            break;
        if (arcGate == NAV_GATE_NONE)
        {
            cellGate = ds_grid_get(gt, edgeCol, yy);
            if (cellGate != NAV_GATE_NONE && cellGate != sourceGate)
                arcGate = cellGate;
        }
        dropped += 1;
        landed = ds_grid_get(ng, edgeCol, yy);
        if (landed >= 0)
            break;
    }
    if (landed >= 0 && landed != i)
    {
        if (arcGate == NAV_GATE_NONE)
            arcGate = global.navGenNGate[landed];
        navGenEdgeAdd(i, landed, NAV_EDGE_FALL, 0, dropped, max(1, dropped), arcGate, edgeCol, -1);
    }
}
