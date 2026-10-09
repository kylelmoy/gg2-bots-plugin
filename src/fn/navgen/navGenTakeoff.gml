// navGenTakeoff(fromRow, ax0, ax1, toRow, bx0, bx1, dir, toNode):
// NavArcModel.Takeoff with TryLeads/TryLead/Landing/Flight inlined - the
// cheapest takeoff column on the source run from which an arc onto the target
// run [bx0, bx1] on toRow is flyable, or -1. Takeoffs step away from the
// column nearest the target; at each, landing leads are tried largest first
// (and, for the double jump, every re-jump tick). On success the arc is in
// global.navGenArcLand, ArcTicks, ArcVx, ArcCap, ArcRejump.
var fromRow, ax0, ax1, toRow, bx0, bx1, dir, toNode, basis, tries, needRise, off, from, cap;
var lead, q, nr, col, d, t, vx, ok, dj, limit, any;
fromRow = argument0;
ax0 = argument1;
ax1 = argument2;
toRow = argument3;
bx0 = argument4;
bx1 = argument5;
dir = argument6;
toNode = argument7;
dj = (global.navGenModelKind == NAV_GEN_DJ);

if (dir < 0)
{
    basis = max(ax0, min(ax1, bx1 + 1));
    tries = min(NAV_JUMP_TAKEOFF_TRIES, ax1 - basis + 1);
    limit = bx0;
}
else
{
    basis = min(ax1, max(ax0, bx0 - 1));
    tries = min(NAV_JUMP_TAKEOFF_TRIES, basis - ax0 + 1);
    limit = bx1;
}
needRise = (fromRow - toRow) * NAV_CELL_SIZE;
nr = 1;
if (dj)
    nr = global.navGenRejumpCount;

for (off = 0; off < tries; off += 1)
{
    if (dir < 0)
        from = basis + off;
    else
        from = basis - off;
    cap = navGenCeiling(from, fromRow, dir, limit, needRise);
    // Flight time depends on the ceiling (and re-jump), not on the lead.
    any = false;
    for (q = 0; q < nr; q += 1)
    {
        if (dj)
            global.navGenRejump = global.navGenRejumpTicks[q];
        t = navGenFlightTime(fromRow, toRow, cap);
        if (t > global.navGenMaxTicks)
            t = -1;
        global.navGenFlightQ[q] = t;
        if (t >= 0)
            any = true;
    }
    if (!any)
        continue;
    for (lead = NAV_JUMP_LAND_LEAD; lead >= 0; lead -= 1)
    {
        // Landing: `lead` columns into the run past the takeoff.
        if (dir < 0)
        {
            col = min(bx1, from - 1) - lead;
            if (col < bx0)
                continue;
        }
        else
        {
            col = max(bx0, from + 1) + lead;
            if (col > bx1)
                continue;
        }
        d = abs(col - from);
        for (q = 0; q < nr; q += 1)
        {
            // Flight: refused past NAV_JUMP_VX or the model's tick cap.
            t = global.navGenFlightQ[q];
            if (t < 0)
                continue;
            if (d * NAV_CELL_SIZE > NAV_JUMP_VX * t)
                continue;
            if (dj)
                global.navGenRejump = global.navGenRejumpTicks[q];
            vx = d * NAV_CELL_SIZE / t;
            ok = navGenCanFly(from, vx, t, bx0, bx1);
            if (!ok)
                continue;
            ok = navGenFlyable(from, fromRow, col, dir, t, vx, cap, toNode);
            if (!ok)
                continue;
            global.navGenArcLand = col;
            global.navGenArcTicks = t;
            global.navGenArcVx = vx;
            global.navGenArcCap = cap;
            if (dj)
                global.navGenArcRejump = global.navGenRejump;
            else
                global.navGenArcRejump = -1;
            return from;
        }
    }
}
global.navGenArcLand = -1;
global.navGenArcTicks = -1;
global.navGenArcVx = 0;
global.navGenArcCap = 0;
global.navGenArcRejump = -1;
return -1;
