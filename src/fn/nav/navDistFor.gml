// navDistFor(team, hasIntel, setupGatesClosed, canDoubleJump, canRocketJump,
// canStickyJump): NavDistanceSet.For - the table for this asker (a NavQuery,
// as its six arguments), or -1 when no tables are loaded (the C#'s null:
// search with the straight-line heuristic).
//
// An exact profile match: a table whose arc set equals the asker's own is
// admissible and the tightest there is. Only the three class arcs pick the
// table; team, intel and setup gates only ever REMOVE edges, so a table built
// with every gate open is still a lower bound for any gated asker.
//
// The handle is valid until the next navDistLoad/navDistFree - i.e. until
// global.botNavGeneration changes. Pass it to navSearchFind, navDistBetween,
// navDistNextHop.
var k;
if (!global.navDistReady || !global.botNavReady)
    return -1;
k = 0;
if (argument3)
    k += NAV_DIST_DOUBLE_JUMP_BIT;
if (argument4)
    k += NAV_DIST_ROCKET_JUMP_BIT;
if (argument5)
    k += NAV_DIST_STICKY_JUMP_BIT;
return global.navDistByProfile[k];
