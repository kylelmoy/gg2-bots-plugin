// botScriptedApplyHolds(player, char, navKeys): ScriptedBot.ApplyHolds -
// regroup hold, engage hold, back-off band. Grounded and not mid-arc only.
// Returns keys.
var p, char, navKeys, mates, distance, range, goalDist, closeIn, stepDir, safe, minBand;
p = argument0;
char = argument1;
navKeys = argument2;

if (!char.onground or p.botPathFlyingEdge)
    return navKeys;

if (global.botTick < p.botScriptedRegroupUntil)
{
    mates = botScriptedCountMatesNear(p, char);
    if (mates >= BOT_REGROUP_CROWD or mates >= BOT_REGROUP_MATES)
        p.botScriptedRegroupUntil = 0;
    else
    {
        navKeys &= ~(BOT_KEY_LEFT | BOT_KEY_RIGHT);
        // Stuck detector saw the intended keys.
        p.botPathStuckTicks = 0;
    }
}

if (!p.botCombatTargetExists or !p.botCombatVisible)
{
    // HybridBot's handover reads this.
    p.botScriptedWantsToEngage = false;
    return navKeys;
}

distance = point_distance(char.x, char.y, p.botCombatTargetX, p.botCombatTargetY);
range = botTargetingClassRange(p.class);

// Hold to fight unless carrying, near the goal, or past BOT_ENGAGE_TICKS.
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
    // Close-in class (pyro) walks in, only onto safe ground.
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

// Back off inside the class's min band; replaces the horizontal keys.
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
