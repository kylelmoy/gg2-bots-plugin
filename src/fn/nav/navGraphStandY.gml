// navGraphStandY(node): NavGraph.StandY - origin (chest) y on node: FloorY -
// NAV_FEET_OFFSET.
return (ds_grid_get(global.botNavNodes, NAV_NODE_Y, argument0) + NAV_BOX_H) * NAV_CELL_SIZE - NAV_FEET_OFFSET;
