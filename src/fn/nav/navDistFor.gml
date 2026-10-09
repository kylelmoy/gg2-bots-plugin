// navDistFor(team, hasIntel, setupGatesClosed, canDoubleJump, canRocketJump,
// canStickyJump): NavDistanceSet.For - table handle for this NavQuery; -1 when
// none loaded (straight-line heuristic). Only the class arcs pick the table.
// Valid until global.botNavGeneration changes.
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
