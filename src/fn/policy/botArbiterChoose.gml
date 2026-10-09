// botArbiterChoose(eligible): DecisionQuotaArbiter.Choose - first eligible
// tier (lowest index) whose cost fits, or -1 for the scripted layer.
// One server-wide budget per tick (global.botArbiterBudget, us); tier t
// costs global.botPolicyNetCost[t] (measured).
// No charge here apart from the per-tick reset; botArbiterAdmitted charges.
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
