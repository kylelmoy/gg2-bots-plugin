// botDebugDrawLabels(): lay out and draw the labels botDebugDrawBot queued
// (global.botDebugLabel*[0 .. botDebugLabelCount)). Each sits just above its
// bot; one that would overlap a label already placed moves up above it, so a
// crowd of bots becomes a readable column. Placed lowest first, so columns
// grow upward. A moved label keeps a leader line to its bot.
var n, i, j, k, t, w, h, left, right, top, bottom, moved, hit, ax, ay, tries;
n = global.botDebugLabelCount;
if (n <= 0)
    exit;

// Order by anchor y, lowest on screen (largest y) first.
for (i = 0; i < n; i += 1)
    global.botDebugOrder[i] = i;
for (i = 1; i < n; i += 1)
{
    t = global.botDebugOrder[i];
    j = i - 1;
    while (j >= 0)
    {
        if (global.botDebugLabelY[global.botDebugOrder[j]] >= global.botDebugLabelY[t])
            break;
        global.botDebugOrder[j + 1] = global.botDebugOrder[j];
        j -= 1;
    }
    global.botDebugOrder[j + 1] = t;
}

draw_set_halign(fa_center);
draw_set_valign(fa_top);
for (i = 0; i < n; i += 1)
{
    k = global.botDebugOrder[i];
    ax = global.botDebugLabelX[k];
    ay = global.botDebugLabelY[k];
    w = string_width(global.botDebugLabelText[k]) + 6;
    h = string_height(global.botDebugLabelText[k]) + 2;
    left = ax - w / 2;
    right = ax + w / 2;
    bottom = ay - 30;
    top = bottom - h;
    moved = false;
    // At most one move per label already placed.
    for (tries = 0; tries <= i; tries += 1)
    {
        hit = false;
        for (j = 0; j < i; j += 1)
        {
            if (right < global.botDebugPlacedL[j] || left > global.botDebugPlacedR[j])
                continue;
            if (bottom < global.botDebugPlacedT[j] || top > global.botDebugPlacedB[j])
                continue;
            bottom = global.botDebugPlacedT[j] - 2;
            top = bottom - h;
            hit = true;
            moved = true;
        }
        if (!hit)
            break;
    }
    global.botDebugPlacedL[i] = left;
    global.botDebugPlacedR[i] = right;
    global.botDebugPlacedT[i] = top;
    global.botDebugPlacedB[i] = bottom;

    if (moved)
    {
        draw_set_color(global.botDebugLabelColor[k]);
        draw_set_alpha(0.5);
        draw_line(ax, ay - 24, ax, bottom);
    }
    draw_set_color(c_black);
    draw_set_alpha(0.55);
    draw_rectangle(left, top, right, bottom, false);
    draw_set_alpha(1);
    draw_set_color(global.botDebugLabelColor[k]);
    draw_text(ax, top + 1, global.botDebugLabelText[k]);
}
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_alpha(1);
