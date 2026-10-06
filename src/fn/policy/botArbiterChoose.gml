// botArbiterChoose(eligible): DecisionQuotaArbiter.Choose - which eligible
// tier may spend a decision now, most capable (lowest index) first, or -1 to
// leave the wheel with the scripted layer.
//
// ONE budget for the whole server, so a firefight where several bots want a
// decision on the same tick cannot spike it: global.botArbiterBudget
// microseconds of decisions a tick ([Bots] Arbiter), against which each
// tier's decision is priced at its MEASURED GML cost,
// global.botPolicyNetCost[t] (botPolicyNetLoadFile, botPolicyDecide). A bot
// refused here plays the tick on the scripted layer, which is a complete bot.
//
// Advisory and side-effect free apart from the per-tick reset: what is spent
// is charged by botArbiterAdmitted only when a decision really happened.
// Spent in poll order (with(Player) order), so the earliest-joined bots take
// the budget first - deterministic, not fair, as the C#.
var eligible, remain, bit, t;
eligible = argument0;
if (global.botArbiterTick != global.botTick)
{
    global.botArbiterTick = global.botTick;
    global.botArbiterSpent = 0;
}
remain = global.botArbiterBudget - global.botArbiterSpent;
bit = 1;
for (t = 0; t < global.botPolicyNetCount; t += 1)
{
    if ((eligible & bit) != 0)
        if (global.botPolicyNetCost[t] <= remain)
            return t;
    bit *= 2;
}
return -1;
