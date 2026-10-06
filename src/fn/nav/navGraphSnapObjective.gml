// navGraphSnapObjective(worldX, worldY): NavGraph.SnapObjective
// (botObjectiveUpdate's downward search) - the first node resolvable below a
// map object, and where a bot would stand on it.
//
// Map objects are not anchored the way a character is (koth_corinth's marker
// floats 48px above its floor, koth_harvest's 66px), so this searches down a
// cell at a time, up to NAV_MAX_FALL cells, and derives the goal from the node
// it finds.
//
// Returns NavSnap: Node in global.botRet (-1 if the search fell through), and
// global.botRetDrop (pixels searched down, -1 on a miss), global.botRetGoalX
// (the anchor column clamped into the node's span, as a stand x; worldX on a
// miss), global.botRetGoalY (the stand y - the chest; worldY on a miss).
var wx, wy, drop, node, column, x0, x1;
wx = argument0;
wy = argument1;
global.botRetDrop = -1;
global.botRetGoalX = wx;
global.botRetGoalY = wy;
if (!global.botNavReady)
    return -1;
for (drop = 0; drop <= NAV_MAX_FALL * NAV_CELL_SIZE; drop += NAV_CELL_SIZE)
{
    node = navGraphNodeFromWorld(wx, wy + drop);
    if (node < 0)
        continue;
    column = floor(wx / NAV_CELL_SIZE) - (NAV_BOX_W div 2);
    x0 = ds_grid_get(global.botNavNodes, NAV_NODE_X0, node);
    x1 = ds_grid_get(global.botNavNodes, NAV_NODE_X1, node);
    column = max(x0, min(x1, column));
    global.botRetDrop = drop;
    global.botRetGoalX = (column * NAV_CELL_SIZE) + (NAV_BOX_W * NAV_CELL_SIZE / 2);
    global.botRetGoalY = (ds_grid_get(global.botNavNodes, NAV_NODE_Y, node) + NAV_BOX_H) * NAV_CELL_SIZE - NAV_FEET_OFFSET;
    return node;
}
global.botRetDrop = -1;
global.botRetGoalX = wx;
global.botRetGoalY = wy;
return -1;
