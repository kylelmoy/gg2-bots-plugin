// botDebugDrawNav(): the nav graph under the overlay - every node as its floor
// span, every edge as a line from its takeoff (or the source's centre) to the
// destination's centre, at floor height, coloured by type; a dot marks each
// edge's destination end. The geometry is cached per graph (botNavGeneration)
// in global.botDebugNavGrid, one row per edge [x0, y0, x1, y1, type], and only
// what is in view is drawn.
var gen, n, m, i, e, from, to, take, vx, vy, vw, vh, gx0, gy0, gx1, gy1, type, g;
if (!global.botNavReady)
    exit;
n = global.botNavNodeCount;
m = global.botNavEdgeCount;
gen = global.botNavGeneration;
if (global.botDebugNavGen != gen)
{
    if (global.botDebugNavGrid >= 0)
        ds_grid_destroy(global.botDebugNavGrid);
    for (i = 0; i < n; i += 1)
    {
        navGraphWorldSpan(i);
        global.botDebugNodeL[i] = global.botRetLeft;
        global.botDebugNodeR[i] = global.botRetRight;
        global.botDebugNodeY[i] = navGraphFloorY(i);
    }
    g = ds_grid_create(5, max(1, m));
    for (e = 0; e < m; e += 1)
    {
        from = ds_grid_get(global.botNavEdges, NAV_EDGE_FROM, e);
        to = ds_grid_get(global.botNavEdges, NAV_EDGE_TO, e);
        take = ds_grid_get(global.botNavEdges, NAV_EDGE_TAKEOFF, e);
        if (take >= 0)
            gx0 = navGraphColumnWorldX(take);
        else
            gx0 = (global.botDebugNodeL[from] + global.botDebugNodeR[from]) / 2;
        ds_grid_set(g, 0, e, gx0);
        ds_grid_set(g, 1, e, global.botDebugNodeY[from]);
        ds_grid_set(g, 2, e, (global.botDebugNodeL[to] + global.botDebugNodeR[to]) / 2);
        ds_grid_set(g, 3, e, global.botDebugNodeY[to]);
        ds_grid_set(g, 4, e, ds_grid_get(global.botNavEdges, NAV_EDGE_TYPE, e));
    }
    global.botDebugNavGrid = g;
    global.botDebugNavGen = gen;
}

vx = view_xview[view_current];
vy = view_yview[view_current];
vw = view_wview[view_current];
vh = view_hview[view_current];
g = global.botDebugNavGrid;

draw_set_alpha(0.7);
for (e = 0; e < m; e += 1)
{
    gx0 = ds_grid_get(g, 0, e);
    gx1 = ds_grid_get(g, 2, e);
    if (max(gx0, gx1) < vx || min(gx0, gx1) > vx + vw)
        continue;
    gy0 = ds_grid_get(g, 1, e);
    gy1 = ds_grid_get(g, 3, e);
    if (max(gy0, gy1) < vy || min(gy0, gy1) > vy + vh)
        continue;
    type = ds_grid_get(g, 4, e);
    if (type == NAV_EDGE_WALK)
        draw_set_color(c_gray);
    else if (type == NAV_EDGE_FALL)
        draw_set_color(make_color_rgb(80, 140, 255));
    else if (type == NAV_EDGE_DROPTHROUGH)
        draw_set_color(make_color_rgb(190, 90, 255));
    else if (type == NAV_EDGE_JUMP)
        draw_set_color(c_lime);
    else if (type == NAV_EDGE_DOUBLEJUMP)
        draw_set_color(c_aqua);
    else if (type == NAV_EDGE_ROCKETJUMP)
        draw_set_color(c_orange);
    else
        draw_set_color(c_white);
    draw_line(gx0, gy0, gx1, gy1);
    draw_circle(gx1, gy1, 2, false);
}

draw_set_color(c_white);
draw_set_alpha(0.8);
for (i = 0; i < n; i += 1)
{
    gy0 = global.botDebugNodeY[i];
    if (gy0 < vy || gy0 > vy + vh)
        continue;
    if (global.botDebugNodeR[i] < vx || global.botDebugNodeL[i] > vx + vw)
        continue;
    draw_line_width(global.botDebugNodeL[i], gy0, global.botDebugNodeR[i], gy0, 2);
}
draw_set_alpha(1);
