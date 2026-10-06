// botObjectiveDecide(player, role, spreadX, allowSpot, target, reposting,
//     repostSkip, repostNearBot, useReachable, team, hasIntel, setupGatesClosed,
//     canDoubleJump, canRocketJump, canStickyJump)
// BotObjective.Decide (botObjectiveUpdate): where this bot should be heading,
// given the game mode's objective. Returns the BotGoal:
//     global.botRet           Found
//     global.botRetX, botRetY where to walk (world)
//     global.botRetIsSpot     it came out of the spot search (botGoalSpotFind)
//     global.botRetMustTouch  a goal to occupy rather than cover
//     global.botRetOffset     how far X was moved sideways off the objective
// Hand the five to botObjectiveTryResolve. All zero/false when nothing was found.
//
// Arguments, as the C#'s: role (BOT_ROLE_*), spreadX (botRolesSpreadX, constant
// for the bot's life), allowSpot (false while the caller bans spots), target
// (what the combat half is looking at: its Player instance - a Character is
// accepted too - or noone), reposting / repostSkip / repostNearBot (the caller's
// re-post state, ScriptedBot.ParkedTicks), and the C#'s `NavQuery?
// reachableFor` as useReachable (false = null) plus NavQuery's six fields.
//
// The cascade mirrors basicRoomSetup's instance_exists cascade, but asks the
// ENTITIES (a carried flag has no instance) and only reads the mode itself for
// Dual KotH (botObjectiveControlPoint). Then, in order: role (a defender's anchor
// is its own objective), held (a defender overlooks a point we hold, an attacker
// pushes out toward the enemy spawn), class (a sniper perches, an engineer sits
// on the choke, a spy flanks - never on a goal it must touch), re-post (a bot
// parked doing nothing asks for somewhere else), spot, spread. The medic's
// follow-goal and the flag-carrier chase are moving INSTANCES and return early,
// skipping spot and spread. Runs on the objective cadence (BOT_OBJECTIVE_PERIOD).
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

// A node held from another map's graph means nothing in this one.
gen = 0;
if (variable_global_exists("botSpawnsGen"))
    gen = global.botSpawnsGen;
if (bot.botObjectiveSpotGen != gen)
{
    bot.botObjectiveSpotNode = -1;
    bot.botObjectiveSpotGen = gen;
}

// The combat target's living Character, or -1 (C# `target is { } foe &&
// world.IsAlive(foe)`).
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

// --- the medic's follow-goal -----------------------------------------------
// First, and returns early: following is the medic's job in every mode. An intel
// carrier does not follow. skipFollowers TRUE here (two medics who pick each
// other deadlock in spawn); the combat half asks with false.
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
        // Keep the ally between me and whatever I am looking at. Horizontal
        // only: a place to stand is a one-dimensional choice on a surface.
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
    // Nobody to follow: walk the objective like everyone else.
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
    // Team Deathmatch: the only mode with nothing in the world to walk to.
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

// --- the flag is in somebody's hands -----------------------------------------
// A carried flag has no instance, so the cascade had nothing: chase the moving
// carrier directly - our thief, or the team-mate running theirs home.
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
    // Changed hands or returned in between: keep whatever goal the bot had.
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

// --- somebody is taking our point --------------------------------------------
// Every "stand somewhere better" behaviour is wrong while an enemy is in the zone.
if (contested)
    held = false;

// --- does this bot's class want to stand somewhere else? ----------------------
spotMode = botClassProfileSpotMode(cls);
classWants = false;
if (spotMode != BOT_SPOT_NONE and !carrying)
{
    // Only where the objective is something to cover rather than to reach.
    if (spotMode == BOT_SPOT_STANDOFF)
        classWants = (defending or held or useSpot);
    else if (spotMode == BOT_SPOT_CHOKE)
        classWants = defending;
    else if (spotMode == BOT_SPOT_FLANK)
        classWants = !mustTouch;
}

// A defender's class opinion does not survive its point being taken; an
// attacker's does.
if (contested and defending)
    classWants = false;

// A class with its own positioning opinion does not also take the generic push;
// the engineer's chokepoint IS the push, applied to its anchor.
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
        // Capped: loitering outside an enemy spawn gives up the thing held.
        if (len > BOT_PUSH_DIST)
        {
            pushX = pushX * BOT_PUSH_DIST / len;
            pushY = pushY * BOT_PUSH_DIST / len;
        }
    }
}

// --- the point is already ours: hold it, or push past it ---------------------
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

// --- per-class positioning: REPLACES the shared band -------------------------
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
        // The ANCHOR moves toward where the attack comes from, and a bare point
        // on a route needs no sightline (it can be inside a wall).
        anchorX += pushX;
        anchorY += pushY;
        spotLos = BOT_LOS_ANY;
    }
    else if (spotMode == BOT_SPOT_FLANK)
    {
        // Near the objective with no sightline to it.
        spotLos = BOT_LOS_AVOID;
    }
}

// --- the bot has been standing on this goal doing nothing --------------------
// Ask for a DIFFERENT place: the hold band, replacing the class's, refusing the
// node it stands on, proximity only. Anchored on the objective, or - the last
// resort, once nothing around the objective had a route - on the bot itself,
// with no distance guard (that annulus is what is empty in the pockets this is for).
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
    // The node already chosen for this same question is held rather than
    // re-decided from wherever the walk has reached; a re-post wants a new one.
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

    // Nothing qualified: fall through to the objective's own point, and forget
    // the held node - its band has nothing in it any more.
    bot.botObjectiveSpotNode = -1;
}

// --- spread ------------------------------------------------------------------
// Never on a goal that has to be TOUCHED (the intel, its base) or a contested
// point: an offset there is standing next to the game mode instead of playing
// it. A defender stands BOT_DEFEND_RADIUS beside what it guards, even at 0.
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
