// navGraphFloorY(node): NavGraph.FloorY - the world y of the surface a node
// stands on. The node must exist (the C# indexes without a check too).
return (ds_grid_get(global.botNavNodes, NAV_NODE_Y, argument0) + NAV_BOX_H) * NAV_CELL_SIZE;
