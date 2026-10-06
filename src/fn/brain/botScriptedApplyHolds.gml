// botScriptedApplyHolds(player, char, navKeys): ScriptedBot.ApplyHolds - the
// regroup hold, the engage hold and the back-off band. Each overrides the
// follower's horizontal keys, and only on the ground and not part-way through
// a validated arc: stripping LEFT/RIGHT mid-jump is a different jump.
// Returns the adjusted keys.
var p, char, navKeys, mates, distance, range, goalDist, closeIn, stepDir, safe, minBand;
p = argument0;
char = argument1;
navKeys = argument2;

if (!char.onground or p.botPathFlyingEdge)
    return navKeys;

if (global.botTick < p.botScriptedRegroupUntil)
{
    mates = botScriptedCountMatesNear(p, char);
    // Wait for company, not for a crowd: a pair, not the whole team as one body.
    if (mates >= BOT_REGROUP_CROWD or mates >= BOT_REGROUP_MATES)
        p.botScriptedRegroupUntil = 0;
    else
    {
        navKeys &= ~(BOT_KEY_LEFT | BOT_KEY_RIGHT);
        // The follower ran its stuck detector on the keys it intended to press.
        p.botPathStuckTicks = 0;
    }
}

if (!p.botCombatTargetExists or !p.botCombatVisible)
{
    // Cleared, not left alone: the hold is time-bounded, and HybridBot's
    // handover reads this.
    p.botScriptedWantsToEngage = false;
    return navKeys;
}

distance = point_distance(char.x, char.y, p.botCombatTargetX, p.botCombatTargetY);
range = botTargetingClassRange(p.class);

// Stand and fight instead of walking past - unless carrying, near the goal,
// or the hold has run BOT_ENGAGE_TICKS since the target was acquired.
if (p.botPathHasGoal)
    goalDist = point_distance(char.x, char.y, p.botPathGoalX, p.botPathGoalY);
else
    goalDist = BOT_ENGAGE_GOAL_NEAR + 1;
p.botScriptedWantsToEngage = !char.intel
    and distance <= range
    and global.botTick - p.botCombatTargetAt <= BOT_ENGAGE_TICKS
    and goalDist > BOT_ENGAGE_GOAL_NEAR;

if (p.botScriptedWantsToEngage)
{
    navKeys &= ~(BOT_KEY_LEFT | BOT_KEY_RIGHT);
    p.botPathStuckTicks = 0;
    // A class that must be nearer than it can see (the pyro) walks in - but
    // only where the ground holds, since no route validated this press.
    closeIn = botClassProfileCloseIn(p.class);
    if (closeIn > 0 and distance > closeIn)
    {
        if (p.botCombatTargetX < char.x)
            stepDir = -1;
        else
            stepDir = 1;
        safe = botStepSafe(char, stepDir);
        if (safe)
        {
            if (stepDir > 0)
                navKeys |= BOT_KEY_RIGHT;
            else
                navKeys |= BOT_KEY_LEFT;
        }
    }
}

// Back away from anything inside this class's minimum band. Replaces the
// horizontal keys: pressing both directions is pressing neither.
minBand = botTargetingClassMinBand(p.class);
if (minBand > 0 and distance < minBand)
{
    navKeys &= ~(BOT_KEY_LEFT | BOT_KEY_RIGHT);
    if (p.botCombatTargetX > char.x)
        navKeys |= BOT_KEY_LEFT;
    else
        navKeys |= BOT_KEY_RIGHT;
}

return navKeys;
