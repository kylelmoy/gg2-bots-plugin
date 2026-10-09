// navGenTakeCheapest(): NavGraphBuilder.TakeCheapest - GM8's own
// ds_priority_delete_min, reproduced: the first STRICTLY cheapest of the live
// candidates (global.navGenCandNode/Cost[0..navGenLive)), removed by moving
// the last live entry into its slot. The order decides which candidates fill a
// fixed quota, so it is not a free choice.
var best, k, live, chosen;
live = global.navGenLive;
best = 0;
for (k = 1; k < live; k += 1)
    if (global.navGenCandCost[k] < global.navGenCandCost[best])
        best = k;
chosen = global.navGenCandNode[best];
live -= 1;
global.navGenCandNode[best] = global.navGenCandNode[live];
global.navGenCandCost[best] = global.navGenCandCost[live];
global.navGenLive = live;
return chosen;
