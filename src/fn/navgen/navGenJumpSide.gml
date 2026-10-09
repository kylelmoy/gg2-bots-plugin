// navGenJumpSide(i, side): NavGraphBuilder.JumpEdges for node i, one side
// (0 left, 1 right). Every surface in the envelope with a flyable takeoff is a
// candidate, priced in flight ticks + NAV_JUMP_PENALTY; the cheapest
// NAV_JUMP_MAX_PER_SIDE are kept, plus one slot for the cheapest landing far
// (in rows) from those kept, plus one for the cheapest climb when nothing kept
// climbs. Needs navGenModel(NAV_GEN_JUMP).
var reachMax;
var i, side, n, ay, ax0, ax1, sourceGate, minRow, maxRow, dir, candidates, hasAscent, ry, j, at, reach;
var bx0, bx1, gap, from, kept, bonusUsed, ascentUsed, keptRowCount, chosen, by, claim, far, k, cost, arcGate;
i = argument0;
side = argument1;
n = global.navGenNodeCount;
ay = global.navGenNY[i];
ax0 = global.navGenNX0[i];
ax1 = global.navGenNX1[i];
sourceGate = global.navGenNGate[i];
minRow = max(0, ay - 10);
maxRow = min(global.navGenLastY, ay + NAV_MAX_FALL);
if (side == 0)
    dir = -1;
else
    dir = 1;
global.navGenCurI = i;
global.navGenCurDir = dir;
ds_map_clear(global.navGenRunupCache);
candidates = 0;
hasAscent = false;

for (ry = minRow; ry <= maxRow; ry += 1)
{
    j = global.navGenRowStart[ry];
    if (j < 0)
        continue;
    // The furthest any arc from this row to that one could carry.
    at = ay - ry + NAV_MAX_FALL;
    if (at < 0 || at >= global.navGenReachLen)
        continue;
    reach = global.navGenReach[at];
    if (reach < 0)
        continue;
    while (j < n && global.navGenNY[j] == ry)
    {
        if (j == i)
        {
            j += 1;
            continue;
        }
        bx0 = global.navGenNX0[j];
        bx1 = global.navGenNX1[j];
        // A step a walk edge covers needs no jump.
        if (abs(ry - ay) <= 1 && bx0 <= ax1 + 1 && ax0 <= bx1 + 1)
        {
            j += 1;
            continue;
        }
        if (bx0 > ax1)
            gap = bx0 - ax1;
        else if (ax0 > bx1)
            gap = ax0 - bx1;
        else
            gap = 0;
        reachMax = navGenReachMax(at);
        if (gap * NAV_CELL_SIZE > reach || max(1, gap) * NAV_CELL_SIZE > reachMax)
        {
            j += 1;
            continue;
        }
        from = navGenTakeoff(ay, ax0, ax1, ry, bx0, bx1, dir, j);
        if (from >= 0)
        {
            global.navGenCandNode[candidates] = j;
            global.navGenCandFrom[j] = from;
            global.navGenCandLand[j] = global.navGenArcLand;
            global.navGenCandTicks[j] = global.navGenArcTicks;
            global.navGenCandVx[j] = global.navGenArcVx;
            global.navGenCandCap[j] = global.navGenArcCap;
            global.navGenCandRejump[j] = global.navGenArcRejump;
            global.navGenCandCost[candidates] = max(max(1, abs(global.navGenArcLand - from)), global.navGenArcTicks) + NAV_JUMP_PENALTY;
            candidates += 1;
            if (ry < ay)
                hasAscent = true;
        }
        j += 1;
    }
}
if (candidates == 0)
    exit;

kept = 0;
bonusUsed = false;
ascentUsed = !hasAscent;
keptRowCount = 0;
global.navGenLive = candidates;
while (global.navGenLive > 0 && (kept < NAV_JUMP_MAX_PER_SIDE || !bonusUsed || !ascentUsed))
{
    chosen = navGenTakeCheapest();
    by = global.navGenNY[chosen];
    bx0 = global.navGenNX0[chosen];
    bx1 = global.navGenNX1[chosen];
    claim = 0;
    if (kept >= NAV_JUMP_MAX_PER_SIDE)
    {
        if (by < ay && !ascentUsed)
            claim = 1;
        else if (!bonusUsed)
        {
            far = true;
            for (k = 0; k < keptRowCount; k += 1)
                if (abs(by - global.navGenKeptRows[k]) <= NAV_JUMP_DIVERSITY_ROWS)
                    far = false;
            if (!far)
                continue;
            claim = 2;
        }
        else
            continue;
    }
    // The arc the candidate loop proved (the C# re-derives the same one).
    from = global.navGenCandFrom[chosen];
    global.navGenArcLand = global.navGenCandLand[chosen];
    global.navGenArcTicks = global.navGenCandTicks[chosen];
    global.navGenArcVx = global.navGenCandVx[chosen];
    global.navGenArcCap = global.navGenCandCap[chosen];
    global.navGenArcRejump = global.navGenCandRejump[chosen];
    global.navGenRejump = global.navGenArcRejump;
    cost = max(max(1, abs(global.navGenArcLand - from)), global.navGenArcTicks) + NAV_JUMP_PENALTY;
    arcGate = navGenArcGate(from, ay, dir, chosen, sourceGate);
    navGenEdgeAdd(i, chosen, NAV_EDGE_JUMP, global.navGenArcVx, global.navGenArcTicks, cost, arcGate, from, -1);
    global.navGenKeptRows[keptRowCount] = by;
    keptRowCount += 1;
    if (by < ay)
        ascentUsed = true;
    if (kept < NAV_JUMP_MAX_PER_SIDE)
        kept += 1;
    else if (claim == 2)
        bonusUsed = true;
}
