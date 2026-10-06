// botNavLoad(): install the graph for global.botNavKey from global.botNavDir,
// and its distance tables - BotPopulationService.MapChanged's NavCache.TryLoad
// and LoadDistances. Returns whether a graph is now installed
// (global.botNavReady). Called by botNavMapCheck only.
//
// The tables are kept across a reload when the key and the graph's size are
// unchanged (LoadDistances' _distancesKey): the room reloads every round, a
// .dist is several MB, and one map+area yields one graph. A key whose .dist
// was absent or refused stays without one until the key or size changes.
var key, ok, sig;
key = global.botNavKey;
navGraphFree();
ok = navGraphTryLoad(global.botNavDir + key + ".txt");
if (!ok)
    return false;
global.botNavReady = true;

sig = key + "/" + string(global.botNavNodeCount) + "/" + string(global.botNavEdgeCount);
if (!global.botNavDistancesOn)
{
    navDistFree();
    global.navDistLoadedKey = "";
}
else if (global.navDistLoadedKey != sig)
{
    // navDistLoad frees the old tables first, and leaves none on a refusal:
    // the search then uses the straight-line heuristic.
    navDistLoad(global.botNavDir + key + ".dist");
    global.navDistLoadedKey = sig;
}

global.botNavGeneration += 1;
return true;
