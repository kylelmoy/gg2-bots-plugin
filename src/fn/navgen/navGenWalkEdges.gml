// navGenWalkEdges(): NavGraphBuilder.WalkEdges - runs one mask row apart whose
// spans touch (the free 6 px step), both ways, then same-row touches, refused
// in the direction a door blocks. An edge carries the gate code of the node it
// arrives at.
var n, h, i, j, row, ax0, ax1, bx0, bx1, cost, doorA, doorB;
n = global.navGenNodeCount;
h = global.navGenH;
if (n <= 0)
    exit;
for (i = 0; i < n; i += 1)
{
    row = global.navGenNY[i];
    ax0 = global.navGenNX0[i];
    ax1 = global.navGenNX1[i];
    if (row + 1 > h)
        continue;
    j = global.navGenRowStart[row + 1];
    if (j < 0)
        continue;
    while (j < n && global.navGenNY[j] == row + 1)
    {
        bx0 = global.navGenNX0[j];
        bx1 = global.navGenNX1[j];
        if (bx0 <= ax1 + 1 && ax0 <= bx1 + 1)
        {
            cost = max(1, abs((ax0 + ax1) / 2 - (bx0 + bx1) / 2));
            navGenEdgeAdd(i, j, NAV_EDGE_WALK, 0, 0, cost, global.navGenNGate[j], -1, -1);
            navGenEdgeAdd(j, i, NAV_EDGE_WALK, 0, 0, cost, global.navGenNGate[i], -1, -1);
        }
        j += 1;
    }
}
for (i = 0; i < n - 1; i += 1)
{
    if (global.navGenNY[i] != global.navGenNY[i + 1])
        continue;
    if (global.navGenNX0[i + 1] > global.navGenNX1[i] + 1)
        continue;
    doorA = global.navGenNDoor[i];
    doorB = global.navGenNDoor[i + 1];
    if (doorA != NAV_DOOR_RIGHT && doorB != NAV_DOOR_RIGHT)
        navGenEdgeAdd(i, i + 1, NAV_EDGE_WALK, 0, 0, 1, global.navGenNGate[i + 1], -1, -1);
    if (doorA != NAV_DOOR_LEFT && doorB != NAV_DOOR_LEFT)
        navGenEdgeAdd(i + 1, i, NAV_EDGE_WALK, 0, 0, 1, global.navGenNGate[i], -1, -1);
}
