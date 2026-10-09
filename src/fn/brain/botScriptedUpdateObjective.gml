// botScriptedUpdateObjective(player, char): ScriptedBot.UpdateObjective -
// spot-goal ending, objective cadence, re-post when parked, retarget throttle.
var p, char, decideNow, got, foe, underFire, reposting, allowSpot, found, x0, y0, resolved, gx, gy, isSpot;
p = argument0;
char = argument1;

if (!p.botScriptedHasObjective or p.botScriptedGoalLocked)
    exit;

decideNow = false;

// Judge a re-post once per attempt.
if (p.botScriptedGoalWasRepost and !p.botScriptedRepostJudged
    and (ds_list_size(p.botPathPath) == 0 or !p.botPathHasGoal or global.botTick >= p.botScriptedRepostUntil))
{
    got = point_distance(char.x, char.y, p.botScriptedRepostFromX, p.botScriptedRepostFromY);
    p.botScriptedRepostJudged = true;
    if (got < BOT_GOAL_RETARGET_DIST)
    {
        botScriptedAdvanceRepost(p);
        // Drop it, or the throttle keeps it forever.
        botOccupancyRemove(p);
        botPathFreePath(p);
        p.botPathHasGoal = false;
        // Never planned: try the next candidate next tick.
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
    // Unplanned class spot: ban spots for a while.
    p.botScriptedSpotBanUntil = global.botTick + BOT_SCRIPTED_SPOT_BAN_TICKS;
}

if (!decideNow and (global.botTick + p.botCombatStagger) mod BOT_OBJECTIVE_PERIOD != 0)
    exit;

// Hold a re-post goal while its route lives.
if (p.botScriptedGoalWasRepost and !p.botScriptedRepostJudged
    and p.botPathHasGoal and ds_list_size(p.botPathPath) > 0 and global.botTick < p.botScriptedRepostUntil)
    exit;

// Only the medic uses foe (stands opposite it from its patient).
foe = noone;
if (p.botCombatTargetExists and p.botCombatTargetKind == BOT_TARGET_KIND_CHARACTER)
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

// Throttle on the resolved node position.
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
