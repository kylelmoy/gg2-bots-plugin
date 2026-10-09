// navGenDistTableStart(): begin table global.navGenDistTable - the reverse
// adjacency (CSR, built once per table) over the edges this profile may use
// (NavDistances.InTable: a double/rocket/sticky jump only with its bit), and
// fresh cost/hop buffers that each goal appends one row to.
var n, m, key, e, type, ok, to, i, slot;
n = global.navGenDistNodes;
m = global.navGenDistEdges;
key = global.navGenDistKeys[global.navGenDistTable];
for (i = 0; i <= n; i += 1)
    global.navGenDistRevStart[i] = 0;
for (e = 0; e < m; e += 1)
{
    type = ds_grid_get(global.botNavEdges, NAV_EDGE_TYPE, e);
    ok = true;
    if (type == NAV_EDGE_DOUBLEJUMP)
        ok = ((key & NAV_DIST_DOUBLE_JUMP_BIT) != 0);
    else if (type == NAV_EDGE_ROCKETJUMP)
        ok = ((key & NAV_DIST_ROCKET_JUMP_BIT) != 0);
    else if (type == NAV_EDGE_STICKYJUMP)
        ok = ((key & NAV_DIST_STICKY_JUMP_BIT) != 0);
    global.navGenDistUse[e] = ok;
    if (ok)
    {
        to = ds_grid_get(global.botNavEdges, NAV_EDGE_TO, e);
        global.navGenDistRevStart[to + 1] += 1;
    }
}
for (i = 0; i < n; i += 1)
{
    global.navGenDistRevStart[i + 1] += global.navGenDistRevStart[i];
    global.navGenDistFill[i] = global.navGenDistRevStart[i];
}
if (global.navGenDistScratch >= 0)
    ds_grid_destroy(global.navGenDistScratch);
// Row p: [0] the edge's From, [1] its cost.
global.navGenDistScratch = ds_grid_create(2, max(1, global.navGenDistRevStart[n]));
for (e = 0; e < m; e += 1)
{
    if (!global.navGenDistUse[e])
        continue;
    to = ds_grid_get(global.botNavEdges, NAV_EDGE_TO, e);
    slot = global.navGenDistFill[to];
    ds_grid_set(global.navGenDistScratch, 0, slot, ds_grid_get(global.botNavEdges, NAV_EDGE_FROM, e));
    ds_grid_set(global.navGenDistScratch, 1, slot, ds_grid_get(global.botNavEdges, NAV_EDGE_COST, e));
    global.navGenDistFill[to] = slot + 1;
}
if (global.navGenDistCost >= 0)
    buffer_destroy(global.navGenDistCost);
if (global.navGenDistHops >= 0)
    buffer_destroy(global.navGenDistHops);
global.navGenDistCost = buffer_create();
global.navGenDistHops = buffer_create();
global.navGenDistAt = 0;
