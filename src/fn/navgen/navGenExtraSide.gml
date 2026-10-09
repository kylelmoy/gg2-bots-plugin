// navGenExtraSide(i, side): the double-jump fan (NavGraphBuilder.DoubleJumpEdges)
// or the rocket-jump fan (RocketJumpEdges) for node i, one side, by the current
// model. Both look only up or level, skip any pair the earlier stages already
// join within NAV_DJ_SKIP_HOPS / NAV_RJ_SKIP_HOPS hops or that this fan already
// emitted, and keep their own quota, so they add edges and never displace a jump.
// The double jump also keeps one slot for a climb past the single-jump apex.
// The two are shaped differently on purpose (C# remarks: access vs variety).
var reachMax;
var i, side, kind, n, ay, ax0, ax1, sourceGate, riseRows, minRow, dir, candidates, hasHighClimb, ry, j;
var bx0, bx1, gap, from, kept, climbUsed, chosen, by, cost, arcGate, penalty, maxPerSide, type, singleApex, key;
i = argument0;
side = argument1;
kind = global.navGenModelKind;
n = global.navGenNodeCount;
ay = global.navGenNY[i];
ax0 = global.navGenNX0[i];
ax1 = global.navGenNX1[i];
sourceGate = global.navGenNGate[i];
singleApex = global.navGenSingleApex;
riseRows = ceil(global.navGenApex / NAV_CELL_SIZE) + 1;
minRow = max(0, ay - riseRows);
if (kind == NAV_GEN_DJ)
{
    penalty = NAV_DJ_PENALTY;
    maxPerSide = NAV_DJ_MAX_PER_SIDE;
    type = NAV_EDGE_DOUBLEJUMP;
}
else
{
    penalty = NAV_RJ_PENALTY;
    maxPerSide = NAV_RJ_MAX_PER_SIDE;
    type = NAV_EDGE_ROCKETJUMP;
}
if (side == 0)
{
    dir = -1;
    if (kind == NAV_GEN_DJ)
        navGenMarkReachable(i, NAV_DJ_SKIP_HOPS);
    else
        navGenMarkReachable(i, NAV_RJ_SKIP_HOPS);
}
else
    dir = 1;
global.navGenCurI = i;
global.navGenCurDir = dir;
ds_map_clear(global.navGenRunupCache);
candidates = 0;
hasHighClimb = false;

for (ry = minRow; ry <= ay; ry += 1)
{
    j = global.navGenRowStart[ry];
    if (j < 0)
        continue;
    while (j < n && global.navGenNY[j] == ry)
    {
        key = i * n + j;
        if (j == i || global.navGenSeenAt[j] == global.navGenSeenStamp || ds_map_exists(global.navGenEmitted, key))
        {
            j += 1;
            continue;
        }
        bx0 = global.navGenNX0[j];
        bx1 = global.navGenNX1[j];
        if (abs(ry - ay) <= 1 && bx0 <= ax1 + 1 && ax0 <= bx1 + 1)
        {
            j += 1;
            continue;
        }
        // Out of any arc's reach (navGenModel's ReachMax): Takeoff would fail.
        if (bx0 > ax1)
            gap = bx0 - ax1;
        else if (ax0 > bx1)
            gap = ax0 - bx1;
        else
            gap = 1;
        reachMax = navGenReachMax(ay - ry + NAV_MAX_FALL);
        if (gap * NAV_CELL_SIZE > reachMax)
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
            global.navGenCandCost[candidates] = max(max(1, abs(global.navGenArcLand - from)), global.navGenArcTicks) + penalty;
            candidates += 1;
            if ((ay - ry) * NAV_CELL_SIZE > singleApex)
                hasHighClimb = true;
        }
        j += 1;
    }
}
if (candidates == 0)
    exit;

kept = 0;
// The rocket fan has no reserved slot.
climbUsed = !hasHighClimb || kind != NAV_GEN_DJ;
global.navGenLive = candidates;
while (global.navGenLive > 0 && (kept < maxPerSide || !climbUsed))
{
    chosen = navGenTakeCheapest();
    key = i * n + chosen;
    if (ds_map_exists(global.navGenEmitted, key))
        continue;
    by = global.navGenNY[chosen];
    if (kept >= maxPerSide)
        if (climbUsed || (ay - by) * NAV_CELL_SIZE <= singleApex)
            continue;
    // The arc the candidate loop proved (the C# re-derives the same one).
    from = global.navGenCandFrom[chosen];
    global.navGenArcLand = global.navGenCandLand[chosen];
    global.navGenArcTicks = global.navGenCandTicks[chosen];
    global.navGenArcVx = global.navGenCandVx[chosen];
    global.navGenArcCap = global.navGenCandCap[chosen];
    global.navGenArcRejump = global.navGenCandRejump[chosen];
    global.navGenRejump = global.navGenArcRejump;
    cost = max(max(1, abs(global.navGenArcLand - from)), global.navGenArcTicks) + penalty;
    arcGate = navGenArcGate(from, ay, dir, chosen, sourceGate);
    navGenEdgeAdd(i, chosen, type, global.navGenArcVx, global.navGenArcTicks, cost, arcGate, from, global.navGenArcRejump);
    ds_map_add(global.navGenEmitted, key, 1);
    if (kind == NAV_GEN_DJ)
        if ((ay - by) * NAV_CELL_SIZE > singleApex)
            climbUsed = true;
    if (kept < maxPerSide)
        kept += 1;
}
