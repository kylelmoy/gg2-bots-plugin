// navGenFlightTime(fromRow, toRow, cap): the current model's FlightTime - how
// long the arc lasts before it comes back down to toRow under a ceiling `cap`
// px up, or -1 if it cannot rise that high. The double jump's uses the
// re-jump tick in global.navGenRejump.
var riseWorld, v0, g, tt, th, clamped, riseEnds, fall, cap1, cap2, hj, riseEnds2, peak, rj, d;
riseWorld = (argument0 - argument1) * NAV_CELL_SIZE;
v0 = global.navGenV0;
g = global.navGenG;
tt = global.navGenTermTicks;
th = global.navGenTermHeight;

if (global.navGenModelKind != NAV_GEN_DJ)
{
    clamped = min(max(argument2, 0), global.navGenApex);
    riseEnds = (v0 - sqrt(max(0, v0 * v0 - 2 * g * clamped))) / g;
    if (riseWorld > clamped)
        return -1;
    fall = clamped - riseWorld;
    if (fall <= th)
        return riseEnds + sqrt(2 * fall / g);
    return riseEnds + tt + (fall - th) / NAV_JUMP_TERM_VY;
}

// RiseAt(rejump, cap1), then a fresh impulse capped by what headroom is left.
rj = global.navGenRejump;
cap1 = min(max(argument2, 0), global.navGenSingleApex);
riseEnds = (v0 - sqrt(max(0, v0 * v0 - 2 * g * cap1))) / g;
if (rj <= riseEnds)
    hj = v0 * rj - g * rj * rj / 2;
else
{
    d = rj - riseEnds;
    if (d <= tt)
        hj = cap1 - g * d * d / 2;
    else
        hj = cap1 - (th + NAV_JUMP_TERM_VY * (d - tt));
}
cap2 = min(max(argument2 - hj, 0), global.navGenSingleApex);
riseEnds2 = (v0 - sqrt(max(0, v0 * v0 - 2 * g * cap2))) / g;
peak = hj + cap2;
if (riseWorld > peak)
    return -1;
fall = peak - riseWorld;
if (fall <= th)
    d = sqrt(2 * fall / g);
else
    d = tt + (fall - th) / NAV_JUMP_TERM_VY;
return rj + riseEnds2 + d;
