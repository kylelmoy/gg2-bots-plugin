// navGenDistSetup(): PluginDistFile.PresentArcs + KeysFor for the installed
// graph, then start the first table. One table per distinct (profile & present),
// ascending; each is a Dijkstra to every goal (NavDistances.Derive).
var n, m, e, type, present, k, masked, dup, i;
n = global.botNavNodeCount;
m = global.botNavEdgeCount;
present = 0;
for (e = 0; e < m; e += 1)
{
    type = ds_grid_get(global.botNavEdges, NAV_EDGE_TYPE, e);
    if (type == NAV_EDGE_DOUBLEJUMP)
        present = present | NAV_DIST_DOUBLE_JUMP_BIT;
    else if (type == NAV_EDGE_ROCKETJUMP)
        present = present | NAV_DIST_ROCKET_JUMP_BIT;
    else if (type == NAV_EDGE_STICKYJUMP)
        present = present | NAV_DIST_STICKY_JUMP_BIT;
}
global.navGenDistPresent = present;
global.navGenDistKeyCount = 0;
for (k = 0; k < NAV_DIST_PROFILES; k += 1)
{
    masked = k & present;
    dup = false;
    for (i = 0; i < global.navGenDistKeyCount; i += 1)
        if (global.navGenDistKeys[i] == masked)
            dup = true;
    if (!dup)
    {
        global.navGenDistKeys[global.navGenDistKeyCount] = masked;
        global.navGenDistKeyCount += 1;
    }
}
// Ascending (masks of an ascending k are not always ascending).
for (i = 1; i < global.navGenDistKeyCount; i += 1)
{
    k = global.navGenDistKeys[i];
    e = i - 1;
    while (e >= 0)
    {
        if (global.navGenDistKeys[e] <= k)
            break;
        global.navGenDistKeys[e + 1] = global.navGenDistKeys[e];
        e -= 1;
    }
    global.navGenDistKeys[e + 1] = k;
}

global.navGenDistNodes = n;
global.navGenDistEdges = m;
global.navGenDistOpen = ds_priority_create();
global.navGenDistTables = ds_list_create();
for (i = 0; i < n; i += 1)
{
    global.navGenDistSeen[i] = 0;
    global.navGenDistClosed[i] = 0;
}
global.navGenDistStampN = 0;
global.navGenDistTable = 0;
navGenDistTableStart();
global.navGenStage = NAV_GEN_STAGE_DIST;
global.navGenStageAt[NAV_GEN_STAGE_DIST] = current_time;
