// botHybridMicroInput(player, char, tier): HybridBot.MicroInput - tier `tier`
// drives this tick, through the difficulty handicap; a decision taken is
// counted and charged to the budget. Returns keys in global.botRet, aim
// degrees in global.botRetAim, distance in global.botRetAimDist.
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

// Wire units back to degrees; botPoll's own quantisation returns `net`.
global.botRetAim = net * 360 / 65536;
global.botRetAimDist = dist;
return keys;
