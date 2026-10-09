// botSuppressSpot(char, lastX, lastY, foeTeam): BotSuppress.Spot - first node
// out from the last-seen spot that this bot has a bullet line to, or
// BOT_SUPPRESS_NO_SPOT. Bounded BFS (BOT_SUPPRESS_HOPS, BOT_SUPPRESS_FRONTIER),
// skipping the source node; gates as foeTeam, no intel, no setup.
var me, lastX, lastY, foeTeam, source, q, seen, head, hops, node, nx, ny, e0, en, e, to, g, ok, best;
me = argument0;
lastX = argument1;
lastY = argument2;
foeTeam = argument3;
if (!global.botNavReady)
    return BOT_SUPPRESS_NO_SPOT;

// Snaps downward.
source = navGraphSnapObjective(lastX, lastY);
if (source < 0)
    return BOT_SUPPRESS_NO_SPOT;

if (!variable_global_exists("botSuppressQueue"))
{
    global.botSuppressQueue = ds_list_create();
    global.botSuppressSeen = ds_map_create();
}
q = global.botSuppressQueue;
seen = global.botSuppressSeen;
ds_list_clear(q);
ds_map_clear(seen);
ds_list_add(q, source);
ds_map_add(seen, source, 1);

best = BOT_SUPPRESS_NO_SPOT;
head = 0;
hops = 0;
while (head < ds_list_size(q) and hops < BOT_SUPPRESS_HOPS)
{
    node = ds_list_find_value(q, head);
    head += 1;
    hops += 1;

    if (node != source)
    {
        botSuppressCentre(node);
        nx = global.botRetX;
        ny = global.botRetY;
        if (!collision_line_bulletblocking(me.x, me.y, nx, ny))
        {
            best = node;
            break;
        }
    }

    e0 = ds_grid_get(global.botNavEdgeStart, 0, node);
    if (e0 < 0)
        continue;
    en = ds_grid_get(global.botNavEdgeStart, 1, node);
    for (e = e0; e < e0 + en; e += 1)
    {
        to = ds_grid_get(global.botNavEdges, NAV_EDGE_TO, e);
        if (ds_map_exists(seen, to))
            continue;
        g = ds_grid_get(global.botNavEdges, NAV_EDGE_GATE, e);
        if (g != NAV_GATE_NONE)
        {
            ok = navGraphGatePassable(g, foeTeam, false, false);
            if (!ok)
                continue;
        }
        if (ds_list_size(q) >= BOT_SUPPRESS_FRONTIER or ds_map_size(seen) >= BOT_SUPPRESS_FRONTIER)
            break;
        ds_map_add(seen, to, 1);
        ds_list_add(q, to);
    }
}
return best;
