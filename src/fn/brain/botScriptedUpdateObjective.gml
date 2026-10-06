// botScriptedUpdateObjective(player, char): ScriptedBot.UpdateObjective - how a
// spot goal ends, the objective cadence, the re-post when parked, and the
// retarget throttle. See ScriptedBot.cs for the measurements behind each rule.
var p, char, decideNow, got, foe, underFire, reposting, allowSpot, found, x0, y0, resolved, gx, gy, isSpot;
p = argument0;
char = argument1;

if (!p.botScriptedHasObjective or p.botScriptedGoalLocked)
    exit;

decideNow = false;

// --- how a spot goal ends: once per attempt for a re-post ---
if (p.botScriptedGoalWasRepost and !p.botScriptedRepostJudged
    and (ds_list_size(p.botPathPath) == 0 or !p.botPathHasGoal or global.botTick >= p.botScriptedRepostUntil))
{
    got = point_distance(char.x, char.y, p.botScriptedRepostFromX, p.botScriptedRepostFromY);
    p.botScriptedRepostJudged = true;
    if (got < BOT_GOAL_RETARGET_DIST)
    {
        botScriptedAdvanceRepost(p);
        // Let go of it, or the retarget throttle keeps the failed goal for ever.
        botOccupancyRemove(p);
        botPathFreePath(p);
        p.botPathHasGoal = false;
        // A goal that never planned costs one A* to rule out: try the next
        // candidate next tick rather than at the next objective tick.
        decideNow = (ds_list_size(p.botPathPath) == 0);
    }
    else
    {
        p.botScriptedRepostSkip = 0;
        p.botScriptedRepostNearBot = false;
    }
}
else if (p.botScriptedGoalIsSpot and p.botPathHasGoal and ds_list_size(p.botPathPath) == 0)
{
    // A class spot that never planned is banned for a while.
    p.botScriptedSpotBanUntil = global.botTick + BOT_SCRIPTED_SPOT_BAN_TICKS;
}

// Staggered per bot so a server full of them does not pay every objective
// scan on one frame.
if (!decideNow and (global.botTick + p.botCombatStagger) mod BOT_OBJECTIVE_PERIOD != 0)
    exit;

// A re-post goal is held, not re-decided, while its route lives.
if (p.botScriptedGoalWasRepost and !p.botScriptedRepostJudged
    and p.botPathHasGoal and ds_list_size(p.botPathPath) > 0 and global.botTick < p.botScriptedRepostUntil)
    exit;

// Only the medic reads the combat target: its follow position is on the far
// side of its patient from the enemy.
foe = noone;
if (p.botCombatTargetExists and p.botCombatTargetKind == BOT_TARGET_CHARACTER)
    foe = p.botCombatTargetSlot;

underFire = botScriptedUnderFireWithNoAnswer(p, char);
if (underFire)
    reposting = (p.botScriptedParkedTicks >= BOT_REPOST_UNDER_FIRE_TICKS);
else
    reposting = (p.botScriptedParkedTicks >= BOT_REPOST_TICKS);

allowSpot = (global.botTick >= p.botScriptedSpotBanUntil);
found = botObjectiveDecide(p, p.botScriptedRole, p.botScriptedSpreadX, allowSpot, foe,
    reposting, p.botScriptedRepostSkip, p.botScriptedRepostNearBot, true,
    p.botScriptedQueryTeam, p.botScriptedQueryHasIntel, p.botScriptedQuerySetupGatesClosed,
    p.botScriptedQueryCanDoubleJump, p.botScriptedQueryCanRocketJump, p.botScriptedQueryCanStickyJump);
if (!found)
    exit;
isSpot = global.botRetIsSpot;
resolved = botObjectiveTryResolve(p, found, global.botRetX, global.botRetY, isSpot, global.botRetMustTouch, global.botRetOffset);
if (!resolved)
    exit;
gx = global.botRetX;
gy = global.botRetY;

// The throttle is on the RESOLVED node position.
if (p.botPathHasGoal)
{
    if (point_distance(gx, gy, p.botPathGoalX, p.botPathGoalY) <= BOT_GOAL_RETARGET_DIST)
        exit;
}

if (reposting)
{
    if (point_distance(gx, gy, char.x, char.y) > BOT_GOAL_RETARGET_DIST)
        p.botPathReposts += 1;
}

p.botScriptedGoalIsSpot = isSpot;
p.botScriptedGoalWasRepost = reposting and isSpot;
if (p.botScriptedGoalWasRepost)
{
    p.botScriptedRepostFromX = char.x;
    p.botScriptedRepostFromY = char.y;
    p.botScriptedRepostUntil = global.botTick + BOT_REPOST_TICKS;
    p.botScriptedRepostJudged = false;
}

botFollowerSetGoal(p, gx, gy);
