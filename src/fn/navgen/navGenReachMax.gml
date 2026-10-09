// navGenReachMax(index): the furthest, in px, ANY arc of the current model can
// carry for a rise of index - NAV_MAX_FALL rows, or -1: the longest flight over
// every ceiling a takeoff can see ((r - 1) cells, or the apex) and every
// re-jump tick, capped at the model's tick limit, times NAV_JUMP_VX. Memoised
// in global.navGenReachMemo.
//
// A candidate whose nearest landing is further fails Flight on every takeoff
// and lead, so the fans skip it before searching (not in the C#, which pays
// for the search; the edges are the same - docs/departures/navgen.md).
var i, rowDelta, best, c, cap, k, t, saved;
i = argument0;
if (global.navGenReachMemo[i] != -2)
    return global.navGenReachMemo[i];
rowDelta = i - NAV_MAX_FALL;
saved = global.navGenRejump;
best = -1;
for (c = 0; c <= global.navGenMaxRows + 1; c += 1)
{
    cap = min(c * NAV_CELL_SIZE, global.navGenApex);
    if (c == global.navGenMaxRows + 1)
        cap = global.navGenApex;
    for (k = 0; k < global.navGenRejumpCount; k += 1)
    {
        global.navGenRejump = global.navGenRejumpTicks[k];
        t = navGenFlightTime(rowDelta, 0, cap);
        if (t >= 0)
            best = max(best, NAV_JUMP_VX * min(t, global.navGenMaxTicks));
    }
}
global.navGenRejump = saved;
global.navGenReachMemo[i] = best;
return best;
