// botArbiterAdmitted(cost): DecisionQuotaArbiter.Admitted - charge one
// decision that was actually taken, in microseconds, to this tick's budget.
// Per DECISION, not per tick driven: the held ticks of a decision are free.
if (global.botArbiterTick != global.botTick)
{
    global.botArbiterTick = global.botTick;
    global.botArbiterSpent = 0;
}
global.botArbiterSpent += argument0;
