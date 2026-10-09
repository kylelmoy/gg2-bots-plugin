// navGraphNodeFromWorld(worldX, worldY): NavGraph.NodeFromWorld - node a
// character at worldX, worldY stands on, or -1. Best rank dy * 4 + dx within
// 3 rows / 2 columns; ties go to the lowest index. Feet row is rounded
// (GM8 round is half-to-even, = Gml.Round).
var mx, my, best, bestRank, rowLow, rowHigh, row, i, dy, dx, x0, x1, rank, nodes, n, rows;
if (!global.botNavReady)
    return -1;
nodes = global.botNavNodes;
rows = global.botNavRowStart;
n = global.botNavNodeCount;
mx = floor(argument0 / NAV_CELL_SIZE) - (NAV_BOX_W div 2);
my = round((argument1 + NAV_FEET_OFFSET) / NAV_CELL_SIZE);
best = -1;
bestRank = NAV_INF;
rowLow = max(0, my - NAV_BOX_H - 3);
rowHigh = min(global.botNavMaskH + 1, my - NAV_BOX_H + 3);
for (row = rowLow; row <= rowHigh; row += 1)
{
    i = ds_grid_get(rows, 0, row);
    if (i < 0)
        continue;
    dy = abs(row + NAV_BOX_H - my);
    while (i < n)
    {
        if (ds_grid_get(nodes, NAV_NODE_Y, i) != row)
            break;
        x0 = ds_grid_get(nodes, NAV_NODE_X0, i);
        x1 = ds_grid_get(nodes, NAV_NODE_X1, i);
        dx = 0;
        if (mx < x0)
            dx = x0 - mx;
        else if (mx > x1)
            dx = mx - x1;
        if (dx <= 2)
        {
            rank = (dy * 4) + dx;
            if (rank < bestRank)
            {
                bestRank = rank;
                best = i;
            }
        }
        i += 1;
    }
}
return best;
