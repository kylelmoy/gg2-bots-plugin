// botHybridPoll(player, char): HybridBot.Poll - this bot's input for the
// tick; char < 0 when dead.
// Returns keys; aim degrees in global.botRetAim, distance in
// global.botRetAimDist.
// The scripted layer is polled every tick, driving or not. A tier drives
// only if alive, not carrying intel, eligible, engaging and within budget;
// hands change only on a decision boundary.
// Departure: only MacroTask, range 150 and ScriptedCarriesIntel; no
// slot-change reset; all tiers are policies.
var pl, ch, keys, aim, dist, eligible, chosen, engage, boundary, tier;
pl = argument0;
ch = argument1;

pl.botHybridScriptedPolls += 1;
botScriptedPoll(pl, ch);
keys = global.botRet;
aim = global.botRetAim;
dist = global.botRetAimDist;

tier = -1;
if (ch >= 0)
{
    if (!ch.intel)
    {
        eligible = botHybridEligibleTiers(pl.class);
        if (eligible != 0)
        {
            if (pl.botHybridDriving >= 0)
            {
                boundary = botPolicyAtDecisionBoundary(pl);
                if (!boundary)
                    return botHybridMicroInput(pl, ch, pl.botHybridDriving);
            }
            engage = botHandoverShouldEngage(pl, ch, BOT_HYBRID_RANGE, pl.botScriptedWantsToEngage, !global.botEngagesBots, pl.botCombatAlly);
            if (engage)
            {
                chosen = botArbiterChoose(eligible);
                if (chosen >= 0)
                {
                    // always true here; mirrors the C#
                    boundary = botPolicyAtDecisionBoundary(pl);
                    if (boundary)
                        tier = chosen;
                }
            }
        }
    }
}

if (tier >= 0)
{
    botHybridTakeWheel(pl, tier, ch);
    return botHybridMicroInput(pl, ch, tier);
}

botHybridScripted(pl);
global.botRetAim = aim;
global.botRetAimDist = dist;
return keys;
