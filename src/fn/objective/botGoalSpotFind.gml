// botGoalSpotFind(fromX, fromY, targetX, targetY, minDistance, maxDistance,
// los,
//     highBonus, avoidRadius, avoidNode, skip, stickyNode, fromNode, query)
// BotGoalSpot.Find (botGoalSpot): the nav node to stand on to
// shoot/overlook/cover a point. Returns node in global.botRet (-1 if none);
// stand position in global.botRetX/Y (the anchor on a miss).
// global.botGoalSpotTries = sightline tests paid (BotGoalSpot.Tries).
// Departure: no collision world/filter args (uses
// collision_line_bulletblocking); NavQuery packed into `query` (BOT_SPOT_Q_*
// bits, -1 = null) to fit GML's 16 args. los: BOT_LOS_ANY/NEED/AVOID. Defaults:
// avoidRadius 0, avoidNode -1, skip 0, stickyNode -1, fromNode -1, query -1.
// Rank (px): dist from bot + |dist to target - band middle| - highBonus *
// height above target; ties by node index (BOT_SPOT_TIE_EPS). Sightline tested
// best-first, at most BOT_SPOT_TRIES fails. With query and fromNode, only nodes
// reachable under it qualify (botGoalSpotReach). Only rows within maxDistance
// of the anchor are scanned (global.botNavRowStart).
var fromX, fromY, tx, ty, minD, maxD, los, highBonus, avoidRadius, avoidNode, skip, stickyNode, fromNode, query;
var count, filtered, middle, tcol, n, row, x0, x1, col, sx, sy, toTarget, ok, wrong, rank, tries;
var queue, passed, firstNode, firstX, firstY, result, resX, resY, rowLow, rowHigh, r, budget, held, rows;
fromX = argument0;
fromY = argument1;
tx = argument2;
ty = argument3;
minD = argument4;
maxD = argument5;
los = argument6;
highBonus = argument7;
avoidRadius = argument8;
avoidNode = argument9;
skip = argument10;
stickyNode = argument11;
fromNode = argument12;
query = argument13;

global.botGoalSpotTries = 0;
global.botRetX = tx;
global.botRetY = ty;

if (!global.botNavReady)
    return -1;

count = global.botNavNodeCount;

filtered = (fromNode >= 0 and fromNode < count and query >= 0);
if (filtered)
    botGoalSpotReach(fromNode, query);

global.botRetX = tx;
global.botRetY = ty;

if (maxD <= minD)
    return -1;

middle = (minD + maxD) / 2;
tcol = floor(tx / NAV_CELL_SIZE) - (NAV_BOX_W div 2);
tries = 0;

// Keep stickyNode while it still qualifies (stops goal flip-flopping).
if (stickyNode >= 0 and stickyNode != avoidNode and stickyNode < count)
{
    ok = true;
    if (filtered)
        ok = (ds_grid_get(global.botGoalSpotReachGrid, 0, stickyNode) != 0);
    if (ok)
    {
        row = ds_grid_get(global.botNavNodes, NAV_NODE_Y, stickyNode);
        x0 = ds_grid_get(global.botNavNodes, NAV_NODE_X0, stickyNode);
        x1 = ds_grid_get(global.botNavNodes, NAV_NODE_X1, stickyNode);
        col = min(max(tcol, x0), x1);
        sx = col * NAV_CELL_SIZE + NAV_BOX_W * NAV_CELL_SIZE / 2;
        sy = (row + NAV_BOX_H) * NAV_CELL_SIZE - BOT_OBJ_FEET_OFFSET;
        held = point_distance(sx, sy, tx, ty);
        ok = (held >= minD and held <= maxD);
        if (ok and avoidRadius > 0)
            ok = (point_distance(fromX, fromY, sx, sy) >= avoidRadius);
        if (ok and los != BOT_LOS_ANY)
        {
            tries += 1;
            wrong = collision_line_bulletblocking(sx, sy, tx, ty);
            if (los == BOT_LOS_AVOID)
                ok = wrong;
            else
                ok = !wrong;
        }
        if (ok)
        {
            global.botGoalSpotTries = tries;
            global.botRetX = sx;
            global.botRetY = sy;
            return stickyNode;
        }
    }
}

// Rank the band.
queue = ds_priority_create();

rows = ds_grid_height(global.botNavRowStart);
rowLow = max(0, ceil((ty - maxD + BOT_OBJ_FEET_OFFSET) / NAV_CELL_SIZE) - NAV_BOX_H - 1);
rowHigh = min(rows - 1, floor((ty + maxD + BOT_OBJ_FEET_OFFSET) / NAV_CELL_SIZE) - NAV_BOX_H + 1);
n = -1;
for (r = rowLow; r <= rowHigh; r += 1)
{
    n = ds_grid_get(global.botNavRowStart, 0, r);
    if (n >= 0)
        break;
}

if (n >= 0)
{
    while (n < count)
    {
        row = ds_grid_get(global.botNavNodes, NAV_NODE_Y, n);
        if (row > rowHigh)
            break;
        x0 = ds_grid_get(global.botNavNodes, NAV_NODE_X0, n);
        x1 = ds_grid_get(global.botNavNodes, NAV_NODE_X1, n);
        col = min(max(tcol, x0), x1);
        sx = col * NAV_CELL_SIZE + NAV_BOX_W * NAV_CELL_SIZE / 2;
        sy = (row + NAV_BOX_H) * NAV_CELL_SIZE - BOT_OBJ_FEET_OFFSET;
        toTarget = point_distance(sx, sy, tx, ty);

        // avoidNode refused before ranking (it would win on distance zero).
        ok = (toTarget >= minD and toTarget <= maxD and n != avoidNode);
        if (ok and filtered)
            ok = (ds_grid_get(global.botGoalSpotReachGrid, 0, n) != 0);
        if (ok and avoidRadius > 0)
            ok = (point_distance(fromX, fromY, sx, sy) >= avoidRadius);
        if (ok)
        {
            rank = point_distance(fromX, fromY, sx, sy)
                + abs(toTarget - middle)
                - highBonus * max(0, ty - sy);
            ds_priority_add(queue, n, rank + n * BOT_SPOT_TIE_EPS);
        }
        n += 1;
    }
}

// Best-first; sightline paid only here.
passed = 0;
firstNode = -1;
firstX = 0;
firstY = 0;
result = -1;
resX = tx;
resY = ty;
while (!ds_priority_empty(queue))
{
    n = ds_priority_delete_min(queue);
    row = ds_grid_get(global.botNavNodes, NAV_NODE_Y, n);
    x0 = ds_grid_get(global.botNavNodes, NAV_NODE_X0, n);
    x1 = ds_grid_get(global.botNavNodes, NAV_NODE_X1, n);
    col = min(max(tcol, x0), x1);
    sx = col * NAV_CELL_SIZE + NAV_BOX_W * NAV_CELL_SIZE / 2;
    sy = (row + NAV_BOX_H) * NAV_CELL_SIZE - BOT_OBJ_FEET_OFFSET;

    if (los == BOT_LOS_ANY)
        ok = true;
    else
    {
        tries += 1;
        wrong = collision_line_bulletblocking(sx, sy, tx, ty);
        if (los == BOT_LOS_AVOID)
            ok = wrong;
        else
            ok = !wrong;
    }

    if (ok)
    {
        if (firstNode < 0)
        {
            firstNode = n;
            firstX = sx;
            firstY = sy;
        }
        if (passed < skip)
        {
            passed += 1;
            continue;
        }
        result = n;
        resX = sx;
        resY = sy;
        break;
    }

    if (tries >= BOT_SPOT_TRIES)
        break;
}
ds_priority_clear(queue);

// skip wraps to the first qualifying node.
if (result < 0 and firstNode >= 0)
{
    result = firstNode;
    resX = firstX;
    resY = firstY;
}

// Nothing in the band: nearest reachable node to the band middle, keeping minD
// and los.
if (result < 0 and filtered)
{
    for (n = 0; n < count; n += 1)
    {
        if (n == avoidNode)
            continue;
        if (ds_grid_get(global.botGoalSpotReachGrid, 0, n) == 0)
            continue;
        row = ds_grid_get(global.botNavNodes, NAV_NODE_Y, n);
        x0 = ds_grid_get(global.botNavNodes, NAV_NODE_X0, n);
        x1 = ds_grid_get(global.botNavNodes, NAV_NODE_X1, n);
        col = min(max(tcol, x0), x1);
        sx = col * NAV_CELL_SIZE + NAV_BOX_W * NAV_CELL_SIZE / 2;
        sy = (row + NAV_BOX_H) * NAV_CELL_SIZE - BOT_OBJ_FEET_OFFSET;
        toTarget = point_distance(sx, sy, tx, ty);
        if (toTarget < minD)
            continue;
        ds_priority_add(queue, n, abs(toTarget - middle) + n * BOT_SPOT_TIE_EPS);
    }

    budget = BOT_SPOT_TRIES;
    while (!ds_priority_empty(queue))
    {
        n = ds_priority_delete_min(queue);
        row = ds_grid_get(global.botNavNodes, NAV_NODE_Y, n);
        x0 = ds_grid_get(global.botNavNodes, NAV_NODE_X0, n);
        x1 = ds_grid_get(global.botNavNodes, NAV_NODE_X1, n);
        col = min(max(tcol, x0), x1);
        sx = col * NAV_CELL_SIZE + NAV_BOX_W * NAV_CELL_SIZE / 2;
        sy = (row + NAV_BOX_H) * NAV_CELL_SIZE - BOT_OBJ_FEET_OFFSET;

        if (los == BOT_LOS_ANY)
            ok = true;
        else
        {
            tries += 1;
            wrong = collision_line_bulletblocking(sx, sy, tx, ty);
            if (los == BOT_LOS_AVOID)
                ok = wrong;
            else
                ok = !wrong;
        }

        if (ok)
        {
            result = n;
            resX = sx;
            resY = sy;
            break;
        }

        budget -= 1;
        if (budget <= 0)
            break;
    }
}

ds_priority_destroy(queue);

global.botGoalSpotTries = tries;
if (result < 0)
{
    global.botRetX = tx;
    global.botRetY = ty;
    return -1;
}
global.botRetX = resX;
global.botRetY = resY;
return result;
