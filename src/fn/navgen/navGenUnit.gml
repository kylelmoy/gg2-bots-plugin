// navGenUnit(): one unit of work of the current stage - a mask row, a region
// pass, a node row, a few nodes' falls, one node-side of a fan, one goal of a
// table - and the stage transitions, in NavGenerator.Build's order.
var n, k, ok;
n = global.navGenNodeCount;
switch (global.navGenStage)
{
case NAV_GEN_STAGE_MASK:
    navGenMaskRow(global.navGenI);
    global.navGenI += 1;
    if (global.navGenI >= global.navGenH)
    {
        with (global.navGenDummy)
            instance_destroy();
        global.navGenDummy = noone;
        navGenStamp();
        global.navGenStage = NAV_GEN_STAGE_CLEARANCE;
        global.navGenSub = 0;
    }
    break;

case NAV_GEN_STAGE_CLEARANCE:
    global.navGenSub = navGenClearanceStep(global.navGenSub);
    if (global.navGenSub < 0)
    {
        global.navGenStage = NAV_GEN_STAGE_NODES;
        global.navGenI = 0;
    }
    break;

case NAV_GEN_STAGE_NODES:
    if (global.navGenI <= global.navGenLastY)
    {
        navGenNodesRow(global.navGenI);
        global.navGenI += 1;
        break;
    }
    navGenNodesFinish();
    global.navGenStage = NAV_GEN_STAGE_SIMPLE;
    global.navGenSub = 0;
    global.navGenI = 0;
    break;

case NAV_GEN_STAGE_SIMPLE:
    if (global.navGenSub == 0)
    {
        navGenWalkEdges();
        global.navGenSub = 1;
        global.navGenI = 0;
        break;
    }
    // Falls then drops, a handful of nodes a unit.
    for (k = 0; k < 16; k += 1)
    {
        if (global.navGenI >= n)
            break;
        if (global.navGenSub == 1)
            navGenFallEdges(global.navGenI);
        else
            navGenDropEdges(global.navGenI);
        global.navGenI += 1;
    }
    if (global.navGenI < n)
        break;
    global.navGenI = 0;
    if (global.navGenSub == 1)
    {
        global.navGenSub = 2;
        break;
    }
    navGenModel(NAV_GEN_JUMP);
    global.navGenStage = NAV_GEN_STAGE_JUMP;
    break;

case NAV_GEN_STAGE_JUMP:
    if (global.navGenI < 2 * n)
    {
        navGenJumpSide(global.navGenI div 2, global.navGenI mod 2);
        global.navGenI += 1;
        break;
    }
    navGenAdjacency();
    navGenModel(NAV_GEN_DJ);
    global.navGenStage = NAV_GEN_STAGE_DJ;
    global.navGenI = 0;
    break;

case NAV_GEN_STAGE_DJ:
    if (global.navGenI < 2 * n)
    {
        navGenExtraSide(global.navGenI div 2, global.navGenI mod 2);
        global.navGenI += 1;
        break;
    }
    // Same snapshot, a fresh `emitted` per fan.
    ds_map_clear(global.navGenEmitted);
    navGenModel(NAV_GEN_RJ);
    global.navGenStage = NAV_GEN_STAGE_RJ;
    global.navGenI = 0;
    break;

case NAV_GEN_STAGE_RJ:
    if (global.navGenI < 2 * n)
    {
        navGenExtraSide(global.navGenI div 2, global.navGenI mod 2);
        global.navGenI += 1;
        break;
    }
    global.navGenStage = NAV_GEN_STAGE_WRITE;
    global.navGenSub = 0;
    break;

case NAV_GEN_STAGE_WRITE:
    if (global.navGenSub == 0)
    {
        navGenMoveBoxEdges();
        global.navGenSub = 1;
        break;
    }
    if (global.navGenSub == 1)
    {
        navGenSort();
        global.navGenSub = 2;
        break;
    }
    ok = navGenWrite();
    global.navGenGraphMs = global.navGenMs;
    global.navGenGraphWallMs = current_time - global.navGenStartedAt;
    // Drop the build's grids; the map check installs the file.
    navGenFree();
    global.navGenActive = true;
    if (ok)
        global.navGenStage = NAV_GEN_STAGE_GRAPH_DONE;
    else
        global.navGenStage = NAV_GEN_STAGE_DONE;
    break;

case NAV_GEN_STAGE_DIST:
    navGenDistGoal();
    break;

case NAV_GEN_STAGE_DIST_WRITE:
    ok = navGenDistWrite();
    global.navGenDistOk = ok;
    global.navGenDistWallMs = current_time - global.navGenStartedAt;
    global.navGenStage = NAV_GEN_STAGE_DONE;
    break;
}
