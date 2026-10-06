// botHybridPoll(player, char): HybridBot.Poll - this bot's input for the
// tick. char is player.object, or a negative id (noone / -1) when dead.
// Returns keys in global.botRet, aim degrees in global.botRetAim and aim
// distance in global.botRetAimDist, as botScriptedPoll does.
//
// The scripted layer plays the game; inside the engagement window a policy
// tier owns keys and aim:
// - THE SCRIPTED LAYER THINKS EVERY TICK, whether or not it drives
//   (botScriptedPoll is called first, always: polling it only when it drove
//   cost captures 20 to 7 in gg2-server's measurement).
// - A dead character, and one carrying the intel, are the scripted layer's.
// - A class no tier drives is the scripted layer's entirely.
// - Control changes hands only on a decision boundary: a tier mid-decision
//   keeps the wheel without the gate being asked.
// - Otherwise Handover.ShouldEngage (MacroTask: an enemy within 150 px AND the
//   scripted layer's own engage hold; HumansOnly unless global.botEngagesBots;
//   a medic on the beam never), then the decision budget (botArbiterChoose),
//   then the tier takes the wheel with its aim resynced.
//
// What is not here, because a live server never selects it: the Distance and
// HeadSplit rules, ScriptedCarriesIntel = false, a range other than 150, and
// the C#'s slot-change reset (a Player is its own identity). All tiers are
// policy tiers - GML has one controller kind.
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
                    // The chosen tier's own cadence: always a boundary here,
                    // asked anyway because the C# asks.
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
