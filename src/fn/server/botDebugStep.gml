// botDebugStep(): the overlay's Step - a left click on one of the open HUD's
// toggle buttons flips it; anywhere else inside the HUD box (as botDebugDraw
// last drew it) opens or collapses the HUD. The click is cleared for whatever
// runs after; the game, which steps first, may still have used it.
var i, on;
if (!mouse_check_button_pressed(mb_left))
    exit;
for (i = 0; i < global.botDebugButtonCount; i += 1)
{
    if (mouse_x < global.botDebugButtonX1[i] || mouse_x > global.botDebugButtonX2[i])
        continue;
    if (mouse_y < global.botDebugButtonY1[i] || mouse_y > global.botDebugButtonY2[i])
        continue;
    if (i == 0)
        global.botDebugLabels = !global.botDebugLabels;
    else if (i == 1)
        global.botDebugNav = !global.botDebugNav;
    else
        global.botDebugHandover = !global.botDebugHandover;
    mouse_clear(mb_left);
    exit;
}
if (mouse_x < global.botDebugBoxX1 || mouse_x > global.botDebugBoxX2)
    exit;
if (mouse_y < global.botDebugBoxY1 || mouse_y > global.botDebugBoxY2)
    exit;
global.botDebugOpen = !global.botDebugOpen;
mouse_clear(mb_left);
