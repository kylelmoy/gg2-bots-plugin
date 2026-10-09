// botObjectiveDecide(player, role, spreadX, allowSpot, target, reposting,
//     repostSkip, repostNearBot, useReachable, team, hasIntel,
//     setupGatesClosed, canDoubleJump, canRocketJump, canStickyJump)
// BotObjective.Decide (botObjectiveUpdate): where the bot should head. Returns
// the BotGoal:
//     global.botRet           Found
//     global.botRetX, botRetY where to walk (world)
//     global.botRetIsSpot     from botGoalSpotFind
//     global.botRetMustTouch  occupy rather than cover
//     global.botRetOffset     sideways offset of X
// All zero/false when not found. Pass them to botObjectiveTryResolve. target:
// combat target's Player (or Character) or noone.
// reposting/repostSkip/repostNearBot: caller's re-post state. useReachable
// false = C# reachableFor null; last six = NavQuery fields. Order: medic
// follow, mode objective, carrier chase, held push, class spot, re-post, spot,
// spread.
var bot, role, spreadX, allowSpot, target, reposting, repostSkip, repostNearBot, useReach, query;
var char, myTeam, cls, defending, selfX, selfY, carrying, gen, targetChar;
var follows, ally, mate, wantX, carrier;
var found, useSpot, held, mustTouch, contested, wx, wy, anchorX, anchorY;
var spotMin, spotMax, spotHigh, spotLos, chase, spotMode, classWants, wantPush;
var pushX, pushY, len, hasSpawn, spawnX, spawnY, range, minBand, high;
var avoidRadius, avoidNode, selfNode, sameQuestion, sticky, fromNode, skipArg, spotNode, spotX, spotY;
bot = argument0;
role = argument1;
spreadX = argument2;
allowSpot = argument3;
target = argument4;
reposting = argument5;
repostSkip = argument6;
repostNearBot = argument7;
useReach = argument8;

query = -1;
if (useReach)
{
    query = 0;
    if (argument9 == TEAM_BLUE)
        query = query | BOT_SPOT_Q_BLUE;
    if (argument10)
        query = query | BOT_SPOT_Q_INTEL;
    if (argument11)
        query = query | BOT_SPOT_Q_SETUP;
    if (argument12)
        query = query | BOT_SPOT_Q_DJ;
    if (argument13)
        query = query | BOT_SPOT_Q_RJ;
    if (argument14)
        query = query | BOT_SPOT_Q_SJ;
}

global.botRetX = 0;
global.botRetY = 0;
global.botRetIsSpot = false;
global.botRetMustTouch = false;
global.botRetOffset = 0;

char = bot.object;
if (char == -1)
    return false;

myTeam = bot.team;
cls = bot.class;
defending = (role == BOT_ROLE_DEFEND);
selfX = char.x;
selfY = char.y;
carrying = char.intel;

gen = 0;
if (variable_global_exists("botSpawnsGen"))
    gen = global.botSpawnsGen;
if (bot.botObjectiveSpotGen != gen)
{
    bot.botObjectiveSpotNode = -1;
    bot.botObjectiveSpotGen = gen;
}

// Combat target's living Character, or -1.
targetChar = -1;
if (target != noone and target != -1)
{
    if (instance_exists(target))
    {
        if (target.object_index == Player)
            targetChar = target.object;
        else
            targetChar = target;
    }
}

// Medic follow; returns early. Carriers don't follow. skipFollowers true
// (mutual medics deadlock).
follows = botClassProfileFollows(cls);
if (follows and !carrying)
{
    ally = botAllyFind(bot, BOT_MEDIC_FOLLOW_RANGE, true);
    mate = -1;
    if (ally != noone and ally != -1)
    {
        if (instance_exists(ally))
        {
            if (ally.object_index == Player)
                mate = ally.object;
            else
                mate = ally;
        }
    }
    if (mate != -1)
    {
        // Keep the ally between me and my target; horizontal only.
        wantX = mate.x;
        if (targetChar != -1)
        {
            if (targetChar.x > mate.x)
                wantX -= BOT_MEDIC_OFFSET;
            else
                wantX += BOT_MEDIC_OFFSET;
        }
        global.botRetX = wantX;
        global.botRetY = mate.y;
        global.botRetIsSpot = false;
        global.botRetMustTouch = true;
        global.botRetOffset = 0;
        return true;
    }
}

found = false;
useSpot = false;
held = false;
mustTouch = false;
contested = false;
wx = 0;
wy = 0;
anchorX = 0;
anchorY = 0;
spotMin = 0;
spotMax = 0;
spotHigh = 0;
spotLos = BOT_LOS_NEED;
chase = -1;

if (instance_exists(IntelligenceBase))
{
    found = botObjectiveIntel(char, myTeam, defending);
    wx = global.botRetX;
    wy = global.botRetY;
    mustTouch = global.botRetMustTouch;
    chase = global.botRetChase;
}
else if (instance_exists(GeneratorRed) or instance_exists(GeneratorBlue))
{
    found = botObjectiveGenerator(cls, myTeam, defending);
    wx = global.botRetX;
    wy = global.botRetY;
    anchorX = global.botRetAnchorX;
    anchorY = global.botRetAnchorY;
    spotMin = global.botRetSpotMin;
    spotMax = global.botRetSpotMax;
    spotHigh = global.botRetSpotHigh;
    useSpot = global.botRetUseSpot;
}
else if (instance_exists(ControlPoint))
{
    found = botObjectiveControlPoint(char, myTeam, defending);
    wx = global.botRetX;
    wy = global.botRetY;
    held = global.botRetHeld;
    contested = global.botRetContested;
}
else
{
    // Team Deathmatch.
    found = botObjectiveDeathmatch(bot, char, cls, targetChar);
    wx = global.botRetX;
    wy = global.botRetY;
    anchorX = global.botRetAnchorX;
    anchorY = global.botRetAnchorY;
    spotMin = global.botRetSpotMin;
    spotMax = global.botRetSpotMax;
    spotHigh = global.botRetSpotHigh;
    useSpot = global.botRetUseSpot;
}

// Flag carried: chase the carrier.
if (chase != -1)
{
    carrier = botObjectiveCarrier(chase);
    if (carrier != noone)
    {
        global.botRetX = carrier.x;
        global.botRetY = carrier.y;
        global.botRetIsSpot = false;
        global.botRetMustTouch = true;
        global.botRetOffset = 0;
        return true;
    }
    // Carrier gone (changed hands or returned): keep the current goal.
}

if (!found)
{
    global.botRetX = 0;
    global.botRetY = 0;
    global.botRetIsSpot = false;
    global.botRetMustTouch = false;
    global.botRetOffset = 0;
    return false;
}

// An enemy in the zone cancels holding.
if (contested)
    held = false;

// Class positioning only where the objective is to cover, not reach.
spotMode = botClassProfileSpotMode(cls);
classWants = false;
if (spotMode != BOT_SPOT_NONE and !carrying)
{
    if (spotMode == BOT_SPOT_STANDOFF)
        classWants = (defending or held or useSpot);
    else if (spotMode == BOT_SPOT_CHOKE)
        classWants = defending;
    else if (spotMode == BOT_SPOT_FLANK)
        classWants = !mustTouch;
}

// A defender drops its class spot when contested; an attacker keeps it.
if (contested and defending)
    classWants = false;

// Class-positioned bots skip the generic push; the engineer's choke applies it
// to its anchor.
wantPush = ((held and !defending and !classWants) or (classWants and spotMode == BOT_SPOT_CHOKE));

pushX = 0;
pushY = 0;
if (wantPush)
{
    hasSpawn = botObjectiveNearestEnemySpawn(myTeam, wx, wy);
    spawnX = global.botRetX;
    spawnY = global.botRetY;
    if (hasSpawn)
    {
        pushX = (spawnX - wx) * BOT_PUSH_FRAC;
        pushY = (spawnY - wy) * BOT_PUSH_FRAC;
        len = point_distance(0, 0, pushX, pushY);
        if (len > BOT_PUSH_DIST)
        {
            pushX = pushX * BOT_PUSH_DIST / len;
            pushY = pushY * BOT_PUSH_DIST / len;
        }
    }
}

// Held: defender overlooks the point; attacker pushes past it.
if (held)
{
    if (defending)
    {
        anchorX = wx;
        anchorY = wy;
        spotMin = BOT_ARRIVE_TOL;
        spotMax = BOT_HOLD_RADIUS;
        spotHigh = BOT_SPOT_HIGH_BONUS;
        useSpot = true;
    }
    else
    {
        wx += pushX;
        wy += pushY;
    }
}

// Class positioning replaces the shared band.
if (classWants)
{
    range = botTargetingClassRange(cls);
    minBand = botTargetingClassMinBand(cls);
    high = botClassProfileSpotHigh(cls);
    anchorX = wx;
    anchorY = wy;
    spotMax = range * BOT_SPOT_BAND;
    spotMin = max(minBand, 1);
    spotHigh = high;
    spotLos = BOT_LOS_NEED;
    useSpot = true;

    if (spotMode == BOT_SPOT_STANDOFF)
        spotMin = max(spotMin, spotMax * BOT_SPOT_NEAR_FRAC);
    else if (spotMode == BOT_SPOT_CHOKE)
    {
        // Anchor moves toward the attack; no sightline needed.
        anchorX += pushX;
        anchorY += pushY;
        spotLos = BOT_LOS_ANY;
    }
    else if (spotMode == BOT_SPOT_FLANK)
    {
        // No sightline to the objective.
        spotLos = BOT_LOS_AVOID;
    }
}

// Re-post: hold band, excluding own node, proximity only; anchored on the
// objective, or on the bot (repostNearBot, no distance guard).
avoidRadius = 0;
avoidNode = -1;
selfNode = -1;
if (global.botNavReady)
{
    if (reposting or query >= 0)
        selfNode = navGraphNodeFromWorld(selfX, selfY);
}

if (reposting)
{
    if (repostNearBot)
        avoidRadius = 0;
    else
        avoidRadius = BOT_REPOST_MIN_MOVE;
    avoidNode = selfNode;
    if (repostNearBot)
    {
        anchorX = selfX;
        anchorY = selfY;
    }
    else
    {
        anchorX = wx;
        anchorY = wy;
    }
    spotMin = BOT_ARRIVE_TOL;
    spotMax = BOT_HOLD_RADIUS;
    spotHigh = BOT_SPOT_HIGH_BONUS;
    spotLos = BOT_LOS_ANY;
    useSpot = true;
}

if (useSpot and allowSpot)
{
    // Reuse the held node for the same question, except when re-posting.
    sameQuestion = false;
    if (bot.botObjectiveSpotNode >= 0)
    {
        sameQuestion = (point_distance(anchorX, anchorY, bot.botObjectiveSpotAnchorX, bot.botObjectiveSpotAnchorY) <= BOT_GOAL_RETARGET_DIST
            and spotMin == bot.botObjectiveSpotMin
            and spotMax == bot.botObjectiveSpotMax
            and spotHigh == bot.botObjectiveSpotHigh
            and spotLos == bot.botObjectiveSpotLos);
    }
    sticky = -1;
    if (!reposting and sameQuestion)
        sticky = bot.botObjectiveSpotNode;

    fromNode = -1;
    if (query >= 0)
        fromNode = selfNode;

    skipArg = 0;
    if (reposting)
        skipArg = repostSkip;

    spotNode = botGoalSpotFind(selfX, selfY, anchorX, anchorY, spotMin, spotMax, spotLos, spotHigh, avoidRadius, avoidNode, skipArg, sticky, fromNode, query);
    spotX = global.botRetX;
    spotY = global.botRetY;

    if (spotNode >= 0)
    {
        bot.botObjectiveSpotNode = spotNode;
        bot.botObjectiveSpotAnchorX = anchorX;
        bot.botObjectiveSpotAnchorY = anchorY;
        bot.botObjectiveSpotMin = spotMin;
        bot.botObjectiveSpotMax = spotMax;
        bot.botObjectiveSpotHigh = spotHigh;
        bot.botObjectiveSpotLos = spotLos;

        global.botRetX = spotX;
        global.botRetY = spotY;
        global.botRetIsSpot = true;
        global.botRetMustTouch = mustTouch;
        global.botRetOffset = 0;
        return true;
    }

    // Nothing qualified: use the objective point and drop the held node.
    bot.botObjectiveSpotNode = -1;
}

// Spread: none on must-touch or contested goals; defenders add
// BOT_DEFEND_RADIUS.
if (mustTouch or contested)
    spreadX = 0;
else if (defending)
{
    if (spreadX >= 0)
        spreadX += BOT_DEFEND_RADIUS;
    else
        spreadX -= BOT_DEFEND_RADIUS;
}

global.botRetX = wx + spreadX;
global.botRetY = wy;
global.botRetIsSpot = false;
global.botRetMustTouch = mustTouch;
global.botRetOffset = spreadX;
return true;
