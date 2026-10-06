// navDistFree(): drop the distance tables, if any. Searches then use the
// straight-line heuristic. Safe to call with nothing loaded.
var k;
global.navDistReady = false;
if (global.navDistBuffer >= 0)
    buffer_destroy(global.navDistBuffer);
global.navDistBuffer = -1;
global.navDistNodes = 0;
global.navDistPresent = 0;
global.navDistTableCount = 0;
for (k = 0; k < NAV_DIST_PROFILES; k += 1)
    global.navDistByProfile[k] = -1;
