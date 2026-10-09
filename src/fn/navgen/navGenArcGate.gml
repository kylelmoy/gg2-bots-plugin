// navGenArcGate(from, ay, dir, toNode, sourceGate): NavGraphBuilder.ArcGate -
// re-walk the arc navGenTakeoff just proved (global.navGenArc*) for the first
// gate cell other than the source's; else the landing node's gate. A spawn gate
// in a doorway would otherwise have jump edges hopping straight over it.
var from, ay, dir, toNode, sourceGate, arcGate, ticks, nearest, tsnap, samples, k, t, sx, sy, hgt, cellGate;
from = argument0;
ay = argument1;
dir = argument2;
toNode = argument3;
sourceGate = argument4;
arcGate = NAV_GATE_NONE;
ticks = global.navGenArcTicks;
nearest = round(ticks);
if (abs(ticks - nearest) < 0.000000001)
    tsnap = nearest;
else
    tsnap = ticks;
samples = max(NAV_JUMP_SAMPLES, ceil(tsnap));
for (k = 1; k <= samples; k += 1)
{
    if (arcGate != NAV_GATE_NONE)
        break;
    t = ticks * k / samples;
    sx = round(from + dir * global.navGenArcVx * t / NAV_CELL_SIZE);
    hgt = navGenHeight(t, global.navGenArcCap);
    sy = round(ay - hgt / NAV_CELL_SIZE);
    if (sx < 0 || sx > global.navGenW - NAV_BOX_W || sy < 0 || sy > global.navGenLastY)
        continue;
    cellGate = ds_grid_get(global.navGenGate, sx, sy);
    if (cellGate != NAV_GATE_NONE && cellGate != sourceGate)
        arcGate = cellGate;
}
if (arcGate == NAV_GATE_NONE)
    return global.navGenNGate[toNode];
return arcGate;
