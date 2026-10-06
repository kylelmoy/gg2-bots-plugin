// botBrainService(): once a tick, after the map check and the population.
//
// gg2-server tells its bots about their place in the roster at three moments:
// a new graph (BotPopulationService.MapChanged -> SetMap, then Retarget), a
// change of team or roster (Retarget) and a change of class (Rerole). Here the
// same moments are noticed rather than announced: the graph generation, and a
// signature of every bot's team and of every bot's class.
var sig, csig, gen, i, pl;

gen = global.botNavGeneration;
if (gen != global.botBrainNavGeneration)
{
    global.botBrainNavGeneration = gen;
    if (global.botNavReady)
        botSpawnsLoad();
    with (Player)
        if (botIsBot)
            botScriptedSetMap(id);
    global.botBrainSignature = "";
}

sig = "";
csig = "";
for (i = 0; i < ds_list_size(global.players); i += 1)
{
    pl = ds_list_find_value(global.players, i);
    if (!pl.botIsBot)
        continue;
    sig += string(pl.id) + ":" + string(pl.team) + ",";
    csig += string(pl.id) + ":" + string(pl.class) + ",";
}

if (sig != global.botBrainSignature)
{
    global.botBrainSignature = sig;
    global.botBrainClassSignature = csig;
    botBrainRetarget(true);
}
else if (csig != global.botBrainClassSignature)
{
    global.botBrainClassSignature = csig;
    botBrainRetarget(false);
}
