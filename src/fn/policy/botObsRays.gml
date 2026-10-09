// botObsRays(char): ObservationWriter.WriteGeometry's ray fan - rows
// 116..139, 24 rays probed every 4 px to 320; first solid probe / 320,
// else 1. Walkmask (CollisionMapO) only; off-mask is open.
// Departure: collision_line + binary search picks the first probe to test,
// so a grazed corner can differ (docs/departures/policy.md).
var ch, g, cx, cy, i, dx, dy, dist, lo, hi, mid, k;
ch = argument0;
g = global.botObsGrid;
cx = ch.x;
cy = ch.y;
for (i = 0; i < BOT_OBS_RAYS; i += 1)
{
    dx = global.botObsRayDx[i];
    dy = global.botObsRayDy[i];
    dist = BOT_OBS_RAY_RANGE;
    if (collision_line(cx, cy, cx + dx * BOT_OBS_RAY_RANGE, cy + dy * BOT_OBS_RAY_RANGE, CollisionMapO, true, false) != noone)
    {
        lo = 1;
        hi = BOT_OBS_RAY_PROBES;
        while (lo < hi)
        {
            mid = (lo + hi) div 2;
            if (collision_line(cx, cy, cx + dx * BOT_OBS_RAY_STEP * mid, cy + dy * BOT_OBS_RAY_STEP * mid, CollisionMapO, true, false) != noone)
                hi = mid;
            else
                lo = mid + 1;
        }
        for (k = lo; k <= BOT_OBS_RAY_PROBES; k += 1)
        {
            // C#'s grouping, so .5 rounds alike
            if (collision_point(round(cx + dx * (BOT_OBS_RAY_STEP * k)), round(cy + dy * (BOT_OBS_RAY_STEP * k)), CollisionMapO, true, false) != noone)
            {
                dist = BOT_OBS_RAY_STEP * k;
                break;
            }
        }
    }
    ds_grid_set(g, 0, BOT_OBS_AT_RAY + i, dist / BOT_OBS_RAY_RANGE);
}
