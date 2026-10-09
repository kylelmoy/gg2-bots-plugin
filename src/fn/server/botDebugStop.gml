// botDebugStop(): server stop; remove the overlay, if there is one.
if (!variable_global_exists("botDebugInst"))
    exit;
with (global.botDebugInst)
    instance_destroy();
global.botDebugInst = noone;
if (variable_global_exists("botDebugNavGrid"))
    if (global.botDebugNavGrid >= 0)
        ds_grid_destroy(global.botDebugNavGrid);
global.botDebugNavGrid = -1;
global.botDebugNavGen = -1;
