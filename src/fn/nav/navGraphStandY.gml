// navGraphStandY(node): NavGraph.StandY - where a character standing on this
// node has its origin (its chest): FloorY - NAV_FEET_OFFSET. The formula
// navSetGoalNode uses, and the one navGraphNodeFromWorld inverts.
return (ds_grid_get(global.botNavNodes, NAV_NODE_Y, argument0) + NAV_BOX_H) * NAV_CELL_SIZE - NAV_FEET_OFFSET;
