// botDebugDraw(): the [Bots] Debug overlay, drawn by the overlay instance
// (botDebugStart) in the host's own window - the bots live here, so a listen
// server's host is the only one who can see it. Layers, bottom up: the nav
// graph (toggle), each bot's route (toggle), target, aim-error cone and handover radius
// (toggle), the bots' labels (toggle) stacked so they stay readable, and the
// HUD at top left, collapsed to its title until clicked, with the toggles and
// the difficulty buttons at its foot (botDebugStep reads the clicks). Not in
// the C#.
var vx, vy, hud, k, n, stage, bx, by, i, txt, w, on, dx;
vx = view_xview[view_current];
vy = view_yview[view_current];
draw_set_alpha(1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

if (global.botDebugNav)
    botDebugDrawNav();

global.botDebugLabelCount = 0;
with (Player)
{
    if (!variable_local_exists("botIsBot"))
        continue;
    if (!botIsBot)
        continue;
    if (object == -1)
        continue;
    botDebugDrawBot(id, object);
}
if (global.botDebugLabels)
    botDebugDrawLabels();

// HUD: collapsed to its title until clicked.
if (!global.botDebugOpen)
    hud = "BOT DEBUG (click to open)";
else
{
    hud = "BOT DEBUG (click to close)  " + global.currentMap + " (" + global.botNavKey + ")";
    if (global.botNavReady)
        hud += "#nav: " + string(global.botNavNodeCount) + " nodes, " + string(global.botNavEdgeCount) + " edges";
    else
        hud += "#nav: NO GRAPH - bots fight but do not walk";
    if (global.navGenActive)
    {
        stage = global.navGenStage;
        if (stage < NAV_GEN_STAGE_GRAPH_DONE)
            hud += "#generating graph: stage " + string(stage) + " of " + string(NAV_GEN_STAGE_WRITE) + ", " + string(round(global.navGenMs / 1000)) + " s so far";
        else
        {
            n = max(1, global.navGenDistKeyCount * global.navGenDistNodes);
            k = global.navGenDistTable * global.navGenDistNodes + global.navGenDistAt;
            hud += "#generating distance tables: " + string(floor(100 * k / n)) + "% (routes use the straight-line heuristic until then)";
        }
    }
    else if (global.botNavReady)
    {
        if (global.navDistReady)
            hud += "#distance tables: loaded";
        else
            hud += "#distance tables: none (straight-line heuristic)";
    }
    hud += "#bot layer: " + string(round(10 * global.botCostSum / max(1, global.botCostTicks)) / 10) + " ms/frame avg, " + string(global.botCostMax) + " max; mode " + global.botMode;
    hud += "#label: x,y and nav node, then who drives (scripted or the policy network)";
    hud += "#lines: route, goal X, target (red seen, grey lost)#yellow cone: aim error (narrower = harder difficulty)";
    if (global.botDebugNav)
        hud += "#nav: grey walk, blue fall, purple drop-through, green jump,#cyan double jump, orange rocket jump, white movebox";
    if (global.botDebugHandover)
        hud += "#green circle: an enemy inside it lets the policy take over (bright = driving)";
}

global.botDebugBoxX1 = vx + 4;
global.botDebugBoxY1 = vy + 4;
global.botDebugBoxX2 = vx + 4 + string_width(hud) + 8;
global.botDebugBoxY2 = vy + 4 + string_height(hud) + 8;

// At the foot of the open HUD: the layer toggles (buttons 0-3), and below them
// the difficulty, one button a tier (4-8 are tiers 1-5), lit on the current one.
global.botDebugButtonCount = 0;
if (global.botDebugOpen)
{
    bx = vx + 8;
    by = global.botDebugBoxY2;
    dx = bx + string_width("difficulty:") + 6;
    for (i = 0; i < 9; i += 1)
    {
        if (i == 4)
        {
            global.botDebugBoxX2 = max(global.botDebugBoxX2, bx);
            bx = dx;
            by = global.botDebugButtonY2[0] + 6;
        }
        if (i >= 4)
        {
            if (i == 4)
                txt = "Easy";
            else if (i == 5)
                txt = "Medium";
            else if (i == 6)
                txt = "Hard";
            else if (i == 7)
                txt = "Very hard";
            else
                txt = "Max";
            on = (global.botDifficulty == i - 3);
        }
        else if (i == 0)
        {
            txt = "bot labels";
            on = global.botDebugLabels;
        }
        else if (i == 1)
        {
            txt = "paths";
            on = global.botDebugPaths;
        }
        else if (i == 2)
        {
            txt = "nav graph";
            on = global.botDebugNav;
        }
        else
        {
            txt = "handover radius";
            on = global.botDebugHandover;
        }
        w = string_width(txt) + 10;
        global.botDebugButtonText[i] = txt;
        global.botDebugButtonOn[i] = on;
        global.botDebugButtonX1[i] = bx;
        global.botDebugButtonY1[i] = by;
        global.botDebugButtonX2[i] = bx + w;
        global.botDebugButtonY2[i] = by + string_height(txt) + 6;
        bx += w + 6;
    }
    global.botDebugButtonCount = 9;
    global.botDebugBoxX2 = max(global.botDebugBoxX2, bx);
    global.botDebugBoxY2 = global.botDebugButtonY2[8] + 4;
}

draw_set_color(c_black);
draw_set_alpha(0.6);
draw_rectangle(global.botDebugBoxX1, global.botDebugBoxY1, global.botDebugBoxX2, global.botDebugBoxY2, false);
draw_set_alpha(1);
draw_set_color(c_white);
draw_text(vx + 8, vy + 8, hud);
if (global.botDebugOpen)
    draw_text(vx + 8, global.botDebugButtonY1[4] + 3, "difficulty:");
for (i = 0; i < global.botDebugButtonCount; i += 1)
{
    // Lit when on.
    if (global.botDebugButtonOn[i])
        draw_set_color(make_color_rgb(40, 130, 60));
    else
        draw_set_color(make_color_rgb(50, 50, 50));
    draw_rectangle(global.botDebugButtonX1[i], global.botDebugButtonY1[i], global.botDebugButtonX2[i], global.botDebugButtonY2[i], false);
    draw_set_color(c_white);
    draw_rectangle(global.botDebugButtonX1[i], global.botDebugButtonY1[i], global.botDebugButtonX2[i], global.botDebugButtonY2[i], true);
    draw_text(global.botDebugButtonX1[i] + 5, global.botDebugButtonY1[i] + 3, global.botDebugButtonText[i]);
}
