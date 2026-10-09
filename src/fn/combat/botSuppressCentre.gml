// botSuppressCentre(node): BotSuppress.Centre - chest-height world point of a
// character on this node (run midpoint, floored). Returns global.botRetX/Y
// (global.botRet = X). Caller checks botNavReady.
var col, row;
col = floor((ds_grid_get(global.botNavNodes, NAV_NODE_X0, argument0)
             + ds_grid_get(global.botNavNodes, NAV_NODE_X1, argument0)) / 2);
row = ds_grid_get(global.botNavNodes, NAV_NODE_Y, argument0);
global.botRetX = col * NAV_CELL_SIZE + NAV_BOX_W * NAV_CELL_SIZE / 2;
global.botRetY = (row + NAV_BOX_H) * NAV_CELL_SIZE - BOT_COMBAT_STAND_FEET;
global.botRet = global.botRetX;
