// navGenRunupCols(i, takeoff, dir): NavGraphBuilder.RunupCols - how many
// cells of run-up node i offers behind a jump from column `takeoff` toward
// dir, walking back along continuous floor (walk-edge neighbours that touch
// the frontier and extend past it), capped at BOT_RUNUP_CELLS.
var i, takeoff, dir, n, seen, node, frontier, hop, ay, ax0, ax1, best, ry, j, bx0, bx1, back, skip;
i = argument0;
takeoff = argument1;
dir = argument2;
n = global.navGenNodeCount;
seen = global.navGenRunupSeen;
ds_list_clear(seen);
ds_list_add(seen, i);
node = i;
if (dir > 0)
    frontier = global.navGenNX0[i];
else
    frontier = global.navGenNX1[i];

for (hop = 0; hop < BOT_RUNUP_HOPS; hop += 1)
{
    if (abs(takeoff - frontier) >= BOT_RUNUP_CELLS)
        break;
    ay = global.navGenNY[node];
    ax0 = global.navGenNX0[node];
    ax1 = global.navGenNX1[node];
    best = -1;
    for (ry = ay - 1; ry <= ay + 1; ry += 1)
    {
        if (ry < 0 || ry >= global.navGenH + 2)
            continue;
        j = global.navGenRowStart[ry];
        if (j < 0)
            continue;
        while (j < n && global.navGenNY[j] == ry)
        {
            skip = (j == node);
            if (!skip)
                skip = (ds_list_find_index(seen, j) >= 0);
            bx0 = global.navGenNX0[j];
            bx1 = global.navGenNX1[j];
            if (!skip)
                skip = (bx0 > ax1 + 1 || ax0 > bx1 + 1);
            if (!skip && ry == ay)
            {
                if (dir > 0)
                    back = NAV_DOOR_LEFT;
                else
                    back = NAV_DOOR_RIGHT;
                if (global.navGenNDoor[node] == back || global.navGenNDoor[j] == back)
                    skip = true;
            }
            if (!skip)
            {
                // No short-circuit in GML: never index [best] while it is -1.
                if (dir > 0)
                {
                    if (bx1 >= frontier - 1 && bx1 < frontier)
                    {
                        if (best < 0)
                            best = j;
                        else if (bx0 < global.navGenNX0[best])
                            best = j;
                    }
                }
                else
                {
                    if (bx0 <= frontier + 1 && bx0 > frontier)
                    {
                        if (best < 0)
                            best = j;
                        else if (bx1 > global.navGenNX1[best])
                            best = j;
                    }
                }
            }
            j += 1;
        }
    }
    if (best < 0)
        break;
    ds_list_add(seen, best);
    node = best;
    if (dir > 0)
        frontier = global.navGenNX0[best];
    else
        frontier = global.navGenNX1[best];
}
return min(abs(takeoff - frontier), BOT_RUNUP_CELLS);
