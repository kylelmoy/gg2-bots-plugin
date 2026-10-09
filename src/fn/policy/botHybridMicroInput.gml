// botHybridMicroInput(player, char, tier): HybridBot.MicroInput - `tier`
// drives this tick, handicapped; a decision taken is charged to the budget.
// Returns keys; aim degrees in global.botRetAim, distance in
// global.botRetAimDist.
var pl, ch, tier, keys, net, dist;
pl = argument0;
ch = argument1;
tier = argument2;
pl.botHybridMicroDrove = true;
pl.botHybridMicroTicks += 1;

keys = botPolicyPoll(pl, ch, tier);
net = global.botRetAimNet;
dist = global.botRetAimDist;
keys = botHybridHandicap(pl, keys, net);
net = global.botRetAimNet;

pl.botHybridDecidedThisPoll = pl.botPolicyDecidedThisPoll;
if (pl.botHybridDecidedThisPoll)
{
    pl.botHybridMicroDecisions += 1;
    botArbiterAdmitted(global.botPolicyNetCost[tier]);
}

// botPoll requantises this back to `net`
global.botRetAim = net * 360 / 65536;
global.botRetAimDist = dist;
return keys;
