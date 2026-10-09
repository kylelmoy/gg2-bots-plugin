// navGraphWorldSpan(node): NavGraph.WorldSpan - node span as stand x positions.
// Left in global.botRet and global.botRetLeft, Right in global.botRetRight.
var n;
n = argument0;
global.botRetLeft = (ds_grid_get(global.botNavNodes, NAV_NODE_X0, n) * NAV_CELL_SIZE) + (NAV_BOX_W * NAV_CELL_SIZE / 2);
global.botRetRight = (ds_grid_get(global.botNavNodes, NAV_NODE_X1, n) * NAV_CELL_SIZE) + (NAV_BOX_W * NAV_CELL_SIZE / 2);
return global.botRetLeft;
