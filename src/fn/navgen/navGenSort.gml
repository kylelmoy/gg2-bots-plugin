// navGenSort(): NavEdgeBuffer.SortByFrom - counting-sort the edges by From
// into global.navGenSorted (max(count, 1) rows; an edge naming a node outside
// the graph is dropped), and the nodes into global.navGenSortedNodes
// (NAV_NODE_FIELDS x max(n, 1)), the two grids the cache file holds.
// global.navGenWritten is how many sorted edge rows mean anything.
var n, m, rows, i, e, from, written, pos, g, nodes;
n = global.navGenNodeCount;
m = global.navGenEdgeCount;
g = global.navGenEdges;
rows = max(m, 1);
if (global.navGenSorted >= 0)
    ds_grid_destroy(global.navGenSorted);
global.navGenSorted = ds_grid_create(NAV_EDGE_FIELDS, rows);
ds_grid_clear(global.navGenSorted, 0);
written = 0;
if (m > 0 && n > 0)
{
    for (i = 0; i <= n; i += 1)
        global.navGenAdjFill[i] = 0;
    for (e = 0; e < m; e += 1)
    {
        from = ds_grid_get(g, NAV_EDGE_FROM, e);
        if (from >= 0 && from < n)
            global.navGenAdjFill[from] += 1;
    }
    // Counts become cursors.
    for (i = 0; i < n; i += 1)
    {
        pos = global.navGenAdjFill[i];
        global.navGenAdjFill[i] = written;
        written += pos;
    }
    for (e = 0; e < m; e += 1)
    {
        from = ds_grid_get(g, NAV_EDGE_FROM, e);
        if (from < 0 || from >= n)
            continue;
        pos = global.navGenAdjFill[from];
        ds_grid_set_grid_region(global.navGenSorted, g, 0, e, NAV_EDGE_FIELDS - 1, e, 0, pos);
        global.navGenAdjFill[from] = pos + 1;
    }
}
global.navGenWritten = written;

// A grid has at least one row: an empty graph writes one row of zeroes.
nodes = ds_grid_create(NAV_NODE_FIELDS, max(n, 1));
ds_grid_clear(nodes, 0);
for (i = 0; i < n; i += 1)
{
    ds_grid_set(nodes, NAV_NODE_Y, i, global.navGenNY[i]);
    ds_grid_set(nodes, NAV_NODE_X0, i, global.navGenNX0[i]);
    ds_grid_set(nodes, NAV_NODE_X1, i, global.navGenNX1[i]);
    ds_grid_set(nodes, NAV_NODE_FLAGS, i, global.navGenNFlags[i]);
    ds_grid_set(nodes, NAV_NODE_DOOR, i, global.navGenNDoor[i]);
    ds_grid_set(nodes, NAV_NODE_GATE, i, global.navGenNGate[i]);
}
global.navGenSortedNodes = nodes;
