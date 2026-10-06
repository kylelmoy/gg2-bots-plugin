// botGoalSpotFind(fromX, fromY, targetX, targetY, minDistance, maxDistance, los,
//     highBonus, avoidRadius, avoidNode, skip, stickyNode, fromNode, query)
// BotGoalSpot.Find (botGoalSpot): the nav node to stand on in order to DO
// something to a point - shoot it, overlook it, cover its approach - rather than
// to be on it. Returns BotSpot: Node in global.botRet (-1 if nothing qualified)
// and the node's stand position in global.botRetX / global.botRetY - the anchor
// itself on a miss, so a caller that ignores Node still gets a usable point.
// global.botGoalSpotTries is how many sightline tests it paid for (BotGoalSpot.Tries).
//
// Arguments are the C#'s, minus the collision world and filter (the sightline is
// the game's own collision_line_bulletblocking, which is CollisionFilter.ForBullet)
// and with the NavQuery packed into `query` (BOT_SPOT_Q_* bits, or -1 for C#
// `reachableFor: null`), because 20 arguments do not fit GML's 16. `los` is
// BOT_LOS_ANY / NEED / AVOID. avoidRadius 0, avoidNode -1, skip 0, stickyNode -1,
// fromNode -1, query -1 are the C# defaults.
//
// The shape is botFindTarget's: rank every node in the band cheaply, then pay
// for the sightline only on the best, best-first, stopping at the first that
// passes, and at most BOT_SPOT_TRIES failed lines. Rank, in world pixels:
//     distance from the bot  +  |distance to target - middle of band|
//     -  highBonus * height above the target
// (negative is fine and not clamped). Candidates are ordered with a ds_priority;
// BOT_SPOT_TIE_EPS * node breaks ties by node index as the C#'s sort does.
//
// Reachability is the caller's only when `query` is -1: with a query and a
// fromNode, only nodes the bot's class can route to under it are candidates
// (botGoalSpotReach). Without one, a spot that resolves is not a route that
// exists - BotObjective's caller bans spots that never produce a path.
//
// Speed: the band is a distance from the anchor, so only mask rows whose stand
// height lies within maxDistance of it can qualify, and the nodes are stored
// sorted by row - the ranking pass walks only those rows (global.botNavRowStart)
// instead of the whole graph. Same candidates, same order.
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

// A spot the bot's own class cannot walk to is not a spot.
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

// --- keep the node already chosen for this anchor --------------------------
// The rank's first term is the distance from the BOT, which is walking a graph
// route rather than a straight line, so re-deciding every objective tick makes
// the goal flip between two candidates for ever. Held while it still qualifies;
// the band test is what lets go of it when the objective moves.
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

// --- rank the band ---------------------------------------------------------
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

        // avoidNode is refused BEFORE ranking: the bot's own node scores zero on
        // "walk less" and would win by construction.
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

// --- best-first, paying for the sightline only here ------------------------
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

// The skip WRAPS rather than walking off the end: a caller cycling a fixed
// number of re-post candidates against a band that offers fewer gets the
// first qualifying one - the answer a fresh caller would have had - instead of
// "nothing anywhere", which parks it on the node it is standing on.
if (result < 0 and firstNode >= 0)
{
    result = firstNode;
    resX = firstX;
    resY = firstY;
}

// --- nothing reachable in the band: widen it outward ------------------------
// The reachable node nearest the band's middle that still keeps the minimum
// distance and still has the sightline asked for (dropping the sightline too
// was measured worse). Nothing qualifying at all is a miss.
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
