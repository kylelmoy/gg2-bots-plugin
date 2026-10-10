// botDebugDrawPaths(): the paths layer of the debug overlay (botDebugDraw) -
// the routes of every bot, out to the first node beyond BOT_DEBUG_PATH_RANGE
// of it. An edge on several bots' routes is drawn once, wider for each bot on
// it, in its team's colour or purple when both teams use it, so the routes
// stay readable where the bots converge. Each bot's own segment to the node it
// is heading for and its goal are botDebugDrawBot's. Not in the C#.
var map, count, k, i, n, m, size, cx, cy, bx, by, ax, ay, a, b, key, mask, w, red, blue;
map = ds_map_create();
count = 0;
with (Player)
{
    if (!variable_local_exists("botIsBot"))
        continue;
    if (!botIsBot)
        continue;
    if (object == -1)
        continue;
    cx = object.x;
    cy = object.y;
    if (team == TEAM_RED)
        mask = 1;
    else
        mask = 2;
    size = ds_list_size(botPathPath);
    m = -1;
    for (k = max(0, botPathPathAt + 1); k < size; k += 1)
    {
        n = ds_list_find_value(botPathPath, k);
        if (n < 0 || n >= global.botNavNodeCount)
            break;
        navGraphWorldSpan(n);
        bx = (global.botRetLeft + global.botRetRight) / 2;
        by = navGraphStandY(n);
        if (point_distance(cx, cy, bx, by) > BOT_DEBUG_PATH_RANGE)
            break;
        if (m >= 0)
        {
            // Either direction is the same edge.
            a = min(m, n);
            b = max(m, n);
            key = string(a) + ":" + string(b);
            if (ds_map_exists(map, key))
                i = ds_map_find_value(map, key);
            else
            {
                i = count;
                count += 1;
                ds_map_add(map, key, i);
                global.botDebugEdgeA[i] = a;
                global.botDebugEdgeB[i] = b;
                global.botDebugEdgeBots[i] = 0;
                global.botDebugEdgeTeams[i] = 0;
            }
            global.botDebugEdgeBots[i] += 1;
            global.botDebugEdgeTeams[i] = global.botDebugEdgeTeams[i] | mask;
        }
        m = n;
    }
}
ds_map_destroy(map);

red = make_color_rgb(255, 110, 110);
blue = make_color_rgb(110, 160, 255);
draw_set_alpha(0.8);
for (i = 0; i < count; i += 1)
{
    if (global.botDebugEdgeTeams[i] == 1)
        draw_set_color(red);
    else if (global.botDebugEdgeTeams[i] == 2)
        draw_set_color(blue);
    else
        draw_set_color(make_color_rgb(220, 120, 255));
    navGraphWorldSpan(global.botDebugEdgeA[i]);
    ax = (global.botRetLeft + global.botRetRight) / 2;
    ay = navGraphStandY(global.botDebugEdgeA[i]);
    navGraphWorldSpan(global.botDebugEdgeB[i]);
    bx = (global.botRetLeft + global.botRetRight) / 2;
    by = navGraphStandY(global.botDebugEdgeB[i]);
    w = min(9, 2 * global.botDebugEdgeBots[i] - 1);
    if (w <= 1)
        draw_line(ax, ay, bx, by);
    else
        draw_line_width(ax, ay, bx, by, w);
    draw_circle(ax, ay, max(2, w / 2 + 1), false);
    draw_circle(bx, by, max(2, w / 2 + 1), false);
}
draw_set_alpha(1);
