// navGenAdjacency(): the adjacency of every edge emitted so far, snapshotted
// before the double- and rocket-jump fans and NOT refreshed between them (a
// fan must not see its own output, and a Scout-only edge must not tell the
// Soldier's fan a pair is joined). CSR: node u's successors are rows
// AdjStart[u] .. AdjStart[u + 1] - 1 of the 1-wide grid navGenAdjTo.
var n, m, i, e, u, fill;
n = global.navGenNodeCount;
m = global.navGenEdgeCount;
for (i = 0; i <= n; i += 1)
    global.navGenAdjStart[i] = 0;
for (e = 0; e < m; e += 1)
{
    u = ds_grid_get(global.navGenEdges, NAV_EDGE_FROM, e);
    global.navGenAdjStart[u + 1] += 1;
}
for (i = 0; i < n; i += 1)
{
    global.navGenAdjStart[i + 1] += global.navGenAdjStart[i];
    global.navGenAdjFill[i] = global.navGenAdjStart[i];
}
if (global.navGenAdjTo >= 0)
    ds_grid_destroy(global.navGenAdjTo);
global.navGenAdjTo = ds_grid_create(1, max(1, m));
for (e = 0; e < m; e += 1)
{
    u = ds_grid_get(global.navGenEdges, NAV_EDGE_FROM, e);
    fill = global.navGenAdjFill[u];
    ds_grid_set(global.navGenAdjTo, 0, fill, ds_grid_get(global.navGenEdges, NAV_EDGE_TO, e));
    global.navGenAdjFill[u] = fill + 1;
}
for (i = 0; i < n; i += 1)
    global.navGenSeenAt[i] = -1;
global.navGenSeenStamp = 0;
if (global.navGenEmitted >= 0)
    ds_map_destroy(global.navGenEmitted);
global.navGenEmitted = ds_map_create();
