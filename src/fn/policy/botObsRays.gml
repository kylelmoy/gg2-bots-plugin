// botObsRays(char): ObservationWriter.WriteGeometry's ray fan, rows 116..139.
//
// The C#: 24 rays from the character's origin; along each, probes every 4 px
// out to 320 (probe k at round(origin + dir * 4k), banker's rounding, as
// Math.Round and GM8's round both are); the first probe on a solid walkmask
// cell reports 4k / 320, none reports 1.0. Walkmask only - no doors,
// platforms or gates - and off-mask is open.
//
// The walkmask here is the CollisionMapO instance (CustomMapO is its child),
// the map's collision sprite at 6x scale; a precise collision_point at an
// integer pixel asks exactly whether that pixel's 6x6 cell is solid, and
// outside the sprite is open, as Walkmask.IsSolid's off-mask rule.
//
// Probing all 80 points of 24 rays as interpreted code would cost several
// milliseconds, so each ray is first asked natively:
//   1. collision_line over the whole ray. Clear: 1.0, one call.
//   2. Otherwise a binary search for the shortest prefix origin..probe k whose
//      collision_line hits (about 7 calls). A hit there is a lower bound on the
//      first solid probe, since a solid probe point lies on (within half a
//      pixel of) that prefix.
//   3. From that k, the probes themselves, exactly as the C#, with
//      collision_point, until one is solid - usually the first or second.
// The approximation is the "within half a pixel": a line that grazes a solid
// cell's corner without the rounded probe landing in it, or the reverse.
// docs/departures/policy.md.
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
            // origin + dir * (4k), the C#'s grouping, so a .5 rounds the same way.
            if (collision_point(round(cx + dx * (BOT_OBS_RAY_STEP * k)), round(cy + dy * (BOT_OBS_RAY_STEP * k)), CollisionMapO, true, false) != noone)
            {
                dist = BOT_OBS_RAY_STEP * k;
                break;
            }
        }
    }
    ds_grid_set(g, 0, BOT_OBS_AT_RAY + i, dist / BOT_OBS_RAY_RANGE);
}
