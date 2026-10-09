// navGenMoveBoxEdges(): NavGraphBuilder.MoveBoxEdges - for each MoveBox, enter
// from the node under its horizontal centre and simulate the push tick by tick
// (pushed while inside the box, gravity after) to the first node landed on
// while falling. Cost is ticks alone: a free traversal, no jump penalty.
var k, w, maxRow, entryX, entryNode, entryRow, sourceGate, arcGate, vx, vy, wx, wy, landed, blocked, t;
var cx, cy, cellGate, left, right, top, bottom, bl, ng;
w = global.navGenW;
maxRow = global.navGenLastY;
bl = global.navGenBlocked;
ng = global.navGenNodeGrid;
for (k = 0; k < global.navGenInstCount; k += 1)
{
    if (global.navGenInstStamp[k] != NAV_GEN_STAMP_MOVEBOX)
        continue;
    left = global.navGenInstLeft[k];
    right = global.navGenInstRight[k];
    top = global.navGenInstTop[k];
    bottom = global.navGenInstBottom[k];
    entryX = min(max(round((left + right) / 2 / NAV_CELL_SIZE), 0), w - NAV_BOX_W);
    entryNode = -1;
    entryRow = max(0, floor(top / NAV_CELL_SIZE));
    while (entryRow <= maxRow)
    {
        if (ds_grid_get(bl, entryX, entryRow) != 0)
            break;
        entryNode = ds_grid_get(ng, entryX, entryRow);
        if (entryNode >= 0)
            break;
        entryRow += 1;
    }
    if (entryNode < 0)
        continue;

    sourceGate = global.navGenNGate[entryNode];
    arcGate = NAV_GATE_NONE;
    vx = 0;
    vy = 0;
    wx = entryX * NAV_CELL_SIZE + NAV_CELL_SIZE / 2;
    wy = entryRow * NAV_CELL_SIZE;
    landed = -1;
    blocked = false;
    for (t = 1; t <= NAV_JUMP_MAX_TICKS; t += 1)
    {
        vy += NAV_JUMP_GRAVITY;
        if (wx >= left && wx <= right && wy >= top && wy <= bottom)
        {
            vx += global.navGenInstPushX[k];
            vy += global.navGenInstPushY[k];
        }
        vx = min(max(vx, -15), 15);
        vy = min(max(vy, -15), 15);
        wx += vx;
        wy += vy;
        cx = round(wx / NAV_CELL_SIZE);
        cy = round(wy / NAV_CELL_SIZE);
        if (cx < 0 || cx > w - NAV_BOX_W || cy > maxRow)
        {
            blocked = true;
            break;
        }
        // Above the top of the walkmask is open sky.
        if (cy < 0)
            continue;
        if (ds_grid_get(bl, cx, cy) != 0)
        {
            blocked = true;
            break;
        }
        if (arcGate == NAV_GATE_NONE)
        {
            cellGate = ds_grid_get(global.navGenGate, cx, cy);
            if (cellGate != NAV_GATE_NONE && cellGate != sourceGate)
                arcGate = cellGate;
        }
        landed = ds_grid_get(ng, cx, cy);
        if (landed >= 0 && landed != entryNode && vy >= 0)
            break;
        landed = -1;
    }
    if (blocked || landed < 0)
        continue;
    if (arcGate == NAV_GATE_NONE)
        arcGate = global.navGenNGate[landed];
    navGenEdgeAdd(entryNode, landed, NAV_EDGE_MOVEBOX, 0, t, max(1, t), arcGate, -1, -1);
}
