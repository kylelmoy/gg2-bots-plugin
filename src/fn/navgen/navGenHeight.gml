// navGenHeight(t, cap): the current model's Height - px above the takeoff
// row after t ticks, under a ceiling `cap` px up. Rise until the ceiling (or
// the apex), then fall at gravity up to terminal speed. The double jump adds a
// second impulse at global.navGenRejump.
var t, cap, v0, g, tt, th, clamped, riseEnds, d, cap1, cap2, hj, rj, t2;
t = argument0;
cap = argument1;
v0 = global.navGenV0;
g = global.navGenG;
tt = global.navGenTermTicks;
th = global.navGenTermHeight;

if (global.navGenModelKind != NAV_GEN_DJ)
{
    clamped = min(max(cap, 0), global.navGenApex);
    riseEnds = (v0 - sqrt(max(0, v0 * v0 - 2 * g * clamped))) / g;
    if (t <= riseEnds)
        return v0 * t - g * t * t / 2;
    d = t - riseEnds;
    if (d <= tt)
        return clamped - g * d * d / 2;
    return clamped - (th + NAV_JUMP_TERM_VY * (d - tt));
}

// RiseAt(t, cap1) before the re-jump; hj + RiseAt(t - rejump, cap2) after.
rj = global.navGenRejump;
cap1 = min(max(cap, 0), global.navGenSingleApex);
riseEnds = (v0 - sqrt(max(0, v0 * v0 - 2 * g * cap1))) / g;
if (t <= rj)
    t2 = t;
else
    t2 = rj;
if (t2 <= riseEnds)
    hj = v0 * t2 - g * t2 * t2 / 2;
else
{
    d = t2 - riseEnds;
    if (d <= tt)
        hj = cap1 - g * d * d / 2;
    else
        hj = cap1 - (th + NAV_JUMP_TERM_VY * (d - tt));
}
if (t <= rj)
    return hj;
cap2 = min(max(cap - hj, 0), global.navGenSingleApex);
riseEnds = (v0 - sqrt(max(0, v0 * v0 - 2 * g * cap2))) / g;
t2 = t - rj;
if (t2 <= riseEnds)
    return hj + v0 * t2 - g * t2 * t2 / 2;
d = t2 - riseEnds;
if (d <= tt)
    return hj + cap2 - g * d * d / 2;
return hj + cap2 - (th + NAV_JUMP_TERM_VY * (d - tt));
