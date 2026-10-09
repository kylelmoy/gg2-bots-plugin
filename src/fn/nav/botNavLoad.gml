// botNavLoad(): install the graph and distance tables for global.botNavKey -
// MapChanged's NavCache.TryLoad + LoadDistances. Returns global.botNavReady.
// Tables are kept while key and graph size are unchanged.
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
    // On refusal no tables: search uses the straight-line heuristic.
    navDistLoad(global.botNavDir + key + ".dist");
    global.navDistLoadedKey = sig;
}

global.botNavGeneration += 1;
return true;
