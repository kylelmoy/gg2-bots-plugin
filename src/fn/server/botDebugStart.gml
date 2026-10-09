// botDebugStart(): server start. With [Bots] Debug on, create the overlay -
// a persistent instance drawn above everything that calls botDebugDraw (and
// botDebugStep, which opens and collapses its HUD). Its
// object is made once per game (GM8 cannot delete one). Not in the C#.
if (!variable_global_exists("botDebugObj"))
{
    global.botDebugObj = object_add();
    object_set_persistent(global.botDebugObj, true);
    object_set_depth(global.botDebugObj, -1000000);
    object_event_add(global.botDebugObj, ev_draw, 0, 'event_perform_object(global.botF_botDebugDraw, ev_other, ev_user0);');
    object_event_add(global.botDebugObj, ev_step, ev_step_begin, 'event_perform_object(global.botF_botDebugStep, ev_other, ev_user0);');
}
// The HUD starts collapsed; its box and buttons are set by the first draw.
// Layers: labels on, nav graph and handover radius off.
global.botDebugOpen = false;
global.botDebugLabels = true;
global.botDebugNav = false;
global.botDebugHandover = false;
global.botDebugButtonCount = 0;
global.botDebugLabelCount = 0;
// botDebugDrawNav's geometry cache, rebuilt when the graph changes.
if (variable_global_exists("botDebugNavGrid"))
    if (global.botDebugNavGrid >= 0)
        ds_grid_destroy(global.botDebugNavGrid);
global.botDebugNavGrid = -1;
global.botDebugNavGen = -1;
global.botDebugBoxX1 = 0;
global.botDebugBoxY1 = 0;
global.botDebugBoxX2 = -1;
global.botDebugBoxY2 = -1;
global.botDebugInst = noone;
if (global.botDebug)
    global.botDebugInst = instance_create(0, 0, global.botDebugObj);
