// navGenFlyable(from, fromRow, landCol, dir, ticks, vx, cap, toNode):
// NavArcModel.Flyable - step the proven arc sample by sample and see whether
// the body gets to landCol. Lateral motion steps a column at a time and stops
// against a wall (keeping the vertical motion) but only makes up lost ground
// at NAV_JUMP_VX a tick. On the way down every row crossed is swept: the first
// node's anchor met there is where the jump really ends, and it must be toNode.
var from, fromRow, landCol, dir, ticks, vx, cap, toNode, samples, nearest, tsnap, apexTick;
var cx, cxf, prevRow, tPrev, k, t, sy, want, stepCols, aimCol, heldBack, nxt, sweep, onto;
var air, ng, lastCol, lastRow, h, v0, g, clamped, tt, th, dj, rj, re1, re2, hj, cap2, dd, t2, hgt;
from = argument0;
fromRow = argument1;
landCol = argument2;
dir = argument3;
ticks = argument4;
vx = argument5;
cap = argument6;
toNode = argument7;
air = global.navGenAir;
ng = global.navGenNodeGrid;
lastCol = global.navGenLastX;
lastRow = global.navGenLastY;
h = global.navGenH;

// SamplesFor: an x87 flight time that is an integer is exactly that integer.
nearest = round(ticks);
if (abs(ticks - nearest) < 0.000000001)
    tsnap = nearest;
else
    tsnap = ticks;
samples = max(NAV_JUMP_SAMPLES, ceil(tsnap));

// navGenHeight's curve, inlined: its constants once per arc, not per sample.
v0 = global.navGenV0;
g = global.navGenG;
tt = global.navGenTermTicks;
th = global.navGenTermHeight;
dj = (global.navGenModelKind == NAV_GEN_DJ);
rj = global.navGenRejump;
if (!dj)
{
    clamped = min(max(cap, 0), global.navGenApex);
    re1 = (v0 - sqrt(max(0, v0 * v0 - 2 * g * clamped))) / g;
}
else
{
    clamped = min(max(cap, 0), global.navGenSingleApex);
    re1 = (v0 - sqrt(max(0, v0 * v0 - 2 * g * clamped))) / g;
    if (rj <= re1)
        hj = v0 * rj - g * rj * rj / 2;
    else
    {
        dd = rj - re1;
        if (dd <= tt)
            hj = clamped - g * dd * dd / 2;
        else
            hj = clamped - (th + NAV_JUMP_TERM_VY * (dd - tt));
    }
    cap2 = min(max(cap - hj, 0), global.navGenSingleApex);
    re2 = (v0 - sqrt(max(0, v0 * v0 - 2 * g * cap2))) / g;
}

// The single jump sweeps only once its one rise has ended (RiseEndsAt).
apexTick = 0;
if (!global.navGenSweepWhole)
    apexTick = re1;

cx = from;
cxf = from;
prevRow = fromRow;
tPrev = 0;
for (k = 1; k <= samples; k += 1)
{
    t = ticks * k / samples;
    if (!dj || t <= rj)
    {
        if (t <= re1)
            hgt = v0 * t - g * t * t / 2;
        else
        {
            dd = t - re1;
            if (dd <= tt)
                hgt = clamped - g * dd * dd / 2;
            else
                hgt = clamped - (th + NAV_JUMP_TERM_VY * (dd - tt));
        }
    }
    else
    {
        t2 = t - rj;
        if (t2 <= re2)
            hgt = hj + v0 * t2 - g * t2 * t2 / 2;
        else
        {
            dd = t2 - re2;
            if (dd <= tt)
                hgt = hj + cap2 - g * dd * dd / 2;
            else
                hgt = hj + cap2 - (th + NAV_JUMP_TERM_VY * (dd - tt));
        }
    }
    sy = round(fromRow - hgt / NAV_CELL_SIZE);
    want = from + dir * vx * t / NAV_CELL_SIZE;
    stepCols = NAV_JUMP_VX * (t - tPrev) / NAV_CELL_SIZE;
    if (dir > 0)
        aimCol = round(min(want, cxf + stepCols));
    else
        aimCol = round(max(want, cxf - stepCols));

    heldBack = false;
    while (cx != aimCol)
    {
        nxt = cx + dir;
        if (nxt < 0 || nxt > lastCol)
        {
            heldBack = true;
            break;
        }
        if (sy >= 0)
        {
            // Below the mask: never free (the C# would index past its array).
            if (sy >= h)
            {
                heldBack = true;
                break;
            }
            if (ds_grid_get(air, nxt, sy) != 0)
            {
                heldBack = true;
                break;
            }
        }
        cx = nxt;
    }
    if (heldBack)
        cxf = cx;
    else if (dir > 0)
        cxf = min(want, cxf + stepCols);
    else
        cxf = max(want, cxf - stepCols);
    tPrev = t;

    if (cx < 0 || cx > lastCol || sy > lastRow)
        return false;
    if (sy >= 0)
    {
        if (ds_grid_get(air, cx, sy) != 0)
            return false;
        if (sy > prevRow && (global.navGenSweepWhole || t > apexTick))
        {
            for (sweep = max(0, prevRow + 1); sweep <= sy; sweep += 1)
            {
                onto = ds_grid_get(ng, cx, sweep);
                if (onto >= 0 && onto != toNode)
                    return false;
            }
        }
    }
    prevRow = sy;
}
return (cx == landCol);
