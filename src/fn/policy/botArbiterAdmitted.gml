// botArbiterAdmitted(cost): DecisionQuotaArbiter.Admitted - charge one
// decision taken (us) to this tick's budget. Held ticks are free.
if (global.botArbiterTick != global.botTick)
{
    global.botArbiterTick = global.botTick;
    global.botArbiterSpent = 0;
}
global.botArbiterSpent += argument0;
