// navGenModel(kind): make NAV_GEN_JUMP (NavJumpModel, Heavy), NAV_GEN_DJ
// (NavDoubleJumpModel, Scout) or NAV_GEN_RJ (NavRocketJumpModel.ForRocket,
// Soldier: run-up on the ground law, flight on the rocket law) the current arc
// model. Sets its curve constants, its straight-up ceiling memo, its run-up
// speed table and, for the jump, its reach table.
var kind, v0, g, i, c, v, xx, rp, acc, mx, rowDelta, t, riseRows, apexTick, cand, val, k, dup, len;
kind = argument0;
global.navGenModelKind = kind;
global.navGenRejump = -1;

if (kind == NAV_GEN_RJ)
{
    v0 = (NAV_JUMP_V0 + NAV_RJ_IMPULSE) * NAV_RJ_SPEEDUP;
    g = NAV_RJ_GRAVITY;
}
else
{
    v0 = NAV_JUMP_V0;
    g = NAV_JUMP_GRAVITY;
}
global.navGenV0 = v0;
global.navGenG = g;
global.navGenTermTicks = NAV_JUMP_TERM_VY / g;
global.navGenTermHeight = g * global.navGenTermTicks * global.navGenTermTicks / 2;
global.navGenSingleApex = NAV_JUMP_V0 * NAV_JUMP_V0 / (2 * NAV_JUMP_GRAVITY);

if (kind == NAV_GEN_JUMP)
{
    global.navGenApex = global.navGenSingleApex;
    global.navGenMaxRows = ceil(global.navGenApex / NAV_CELL_SIZE);
    global.navGenMaxTicks = NAV_JUMP_MAX_TICKS;
    global.navGenSweepWhole = false;
    rp = NAV_GEN_RUNPOWER_HEAVY;
}
else if (kind == NAV_GEN_DJ)
{
    global.navGenApex = 2 * global.navGenSingleApex;
    global.navGenMaxRows = ceil(2 * global.navGenSingleApex / NAV_CELL_SIZE) + 1;
    global.navGenMaxTicks = NAV_DJ_MAX_TICKS;
    global.navGenSweepWhole = true;
    rp = NAV_GEN_RUNPOWER_SCOUT;
}
else
{
    global.navGenApex = v0 * v0 / (2 * g);
    global.navGenMaxRows = ceil(global.navGenApex / NAV_CELL_SIZE) + 1;
    global.navGenMaxTicks = NAV_RJ_MAX_TICKS;
    global.navGenSweepWhole = true;
    rp = NAV_GEN_RUNPOWER_SOLDIER;
}

// NavCharacter.Profile / RocketProfile. The ground profile walks the run-up;
// the air one flies the arc (the same one except for the rocket jump).
acc = rp * NAV_GEN_BASE_CONTROL;
mx = abs(rp * NAV_GEN_BASE_CONTROL / (NAV_GEN_BASE_FRICTION - 1));
global.navGenAirMax = mx;
global.navGenRocketLaw = (kind == NAV_GEN_RJ);
if (kind == NAV_GEN_RJ)
{
    global.navGenAirAccel = rp * NAV_RJ_CONTROL;
    global.navGenAirFriction = NAV_RJ_FRICTION;
}
else
{
    global.navGenAirAccel = acc;
    global.navGenAirFriction = NAV_GEN_BASE_FRICTION;
}

// RunupSpeed(cols * cell) for every run-up a node can offer (0..RUNUP_CELLS).
for (c = 0; c <= BOT_RUNUP_CELLS; c += 1)
{
    v = 0;
    xx = 0;
    for (i = 0; i < NAV_GEN_INTEGRATION_CAP && xx < c * NAV_CELL_SIZE; i += 1)
    {
        if (v <= mx)
            v += acc;
        v /= NAV_GEN_BASE_FRICTION;
        xx += v;
    }
    global.navGenRunupV[c] = v;
}

// CapStraight's memo, -1 = not yet.
if (global.navGenCapMemo >= 0)
    ds_grid_destroy(global.navGenCapMemo);
global.navGenCapMemo = ds_grid_create(global.navGenW, max(1, global.navGenLastY + 2));
ds_grid_clear(global.navGenCapMemo, -1);

// NavJumpModel.ReachWorld, every row delta it can be asked for.
if (kind == NAV_GEN_JUMP)
{
    riseRows = ceil(global.navGenApex / NAV_CELL_SIZE) + 2;
    len = NAV_MAX_FALL + riseRows + 2;
    global.navGenReachLen = len;
    for (i = 0; i < len; i += 1)
    {
        rowDelta = i - NAV_MAX_FALL;
        t = navGenFlightTime(rowDelta, 0, global.navGenApex);
        if (t < 0)
            global.navGenReach[i] = -1;
        else
            global.navGenReach[i] = NAV_JUMP_VX * min(t, NAV_JUMP_MAX_TICKS);
    }
}

// NavDoubleJumpModel.BuildRejumpTicks: the apex tick, then 1, half, one and a
// half and twice it, distinct, MidpointRounding.AwayFromZero.
global.navGenRejumpCount = 1;
global.navGenRejumpTicks[0] = -1;
if (kind == NAV_GEN_DJ)
{
    apexTick = max(1, floor(NAV_JUMP_V0 / NAV_JUMP_GRAVITY + 0.5));
    global.navGenRejumpCount = 0;
    for (k = 0; k < 5; k += 1)
    {
        if (k == 0)
            cand = apexTick;
        else if (k == 1)
            cand = 1;
        else if (k == 2)
            cand = floor(apexTick / 2 + 0.5);
        else if (k == 3)
            cand = floor(apexTick * 1.5 + 0.5);
        else
            cand = apexTick * 2;
        val = max(1, floor(cand + 0.5));
        dup = false;
        for (i = 0; i < global.navGenRejumpCount; i += 1)
            if (global.navGenRejumpTicks[i] == val)
                dup = true;
        if (global.navGenRejumpCount < NAV_DJ_TICK_TRIES && !dup)
        {
            global.navGenRejumpTicks[global.navGenRejumpCount] = val;
            global.navGenRejumpCount += 1;
        }
    }
}

// The furthest ANY arc of this model can carry, per row difference: filled
// lazily by navGenReachMax (a row costs ~100 flight times; all of them at once
// stalled a tick for ~150 ms). -2 = not yet.
riseRows = ceil(global.navGenApex / NAV_CELL_SIZE) + 2;
len = NAV_MAX_FALL + riseRows + 2;
global.navGenReachMaxLen = len;
for (i = 0; i < len; i += 1)
    global.navGenReachMemo[i] = -2;
