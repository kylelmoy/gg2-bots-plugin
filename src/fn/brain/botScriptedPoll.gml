// botScriptedPoll(player, char): ScriptedBot.Poll - the navigation half and the
// combat half, ORed into one input.
//
// The follower owns LEFT / RIGHT / JUMP / DOWN, combat owns ATTACK, SPECIAL
// and the aim; the two cannot conflict. Three behaviours live here because
// only here sees both halves: the regroup hold, the engage hold and the
// back-off band (botScriptedApplyHolds). gg2-server's ScriptedBot.cs has the
// reasoning for every line; the comments here only mark where it is.
//
// char is player.object, -1 when dead. Returns keys in global.botRet, aim in
// global.botRetAim (degrees) and aim distance in global.botRetAimDist.
var p, char, navKeys, fireKeys, aim, aimDist, still, dodge, airJump, rocket;
p = argument0;
char = argument1;

if (char == -1)
{
    // A dead bot gives up its route: it comes back somewhere else, and its
    // edges stop being crowded the moment it stops walking them.
    botOccupancyRemove(p);
    botPathFreePath(p);
    p.botScriptedAliveLast = false;
    p.botScriptedParkedTicks = 0;
    p.botScriptedRepostSkip = 0;
    p.botScriptedGoalWasRepost = false;
    p.botScriptedRepostNearBot = false;
    p.botScriptedParkedValid = false;
    global.botRetAim = 0;
    global.botRetAimDist = 0;
    return 0;
}

botScriptedTrackCarrier(p, char);

// A fresh life starts a fresh regroup hold, randomised so a whole team does
// not leave on one frame.
if (!p.botScriptedAliveLast)
    p.botScriptedRegroupUntil = global.botTick + floor(random(BOT_REGROUP_TICKS));
p.botScriptedAliveLast = true;

botScriptedUpdateObjective(p, char);

// The query is rebuilt from LIVE state every tick: a class can change
// mid-life, a rocket jump depends on weapon and health, the team can be moved
// by the autobalance, and the two gate terms change under the bot.
// CanStickyJump is never set on a live bot (the C#'s `Query with { ... }`
// leaves it at the constructor's false).
airJump = botClassProfileAirJump(p.class);
rocket = botRocketCapable(char);
p.botScriptedQueryTeam = p.team;
p.botScriptedQueryHasIntel = char.intel;
p.botScriptedQuerySetupGatesClosed = areSetupGatesClosed();
p.botScriptedQueryCanDoubleJump = airJump;
p.botScriptedQueryCanRocketJump = rocket;

navKeys = 0;
if (global.botNavReady)
{
    navKeys = botFollowerStep(p, char, p.botScriptedQueryTeam, p.botScriptedQueryHasIntel,
        p.botScriptedQuerySetupGatesClosed, p.botScriptedQueryCanDoubleJump,
        p.botScriptedQueryCanRocketJump, p.botScriptedQueryCanStickyJump);
}

fireKeys = botCombatStep(p, char);
aim = global.botRetAim;
aimDist = global.botRetAimDist;

// The launch hand-off: a rocket or sticky jump needs a key from each half, so
// it is applied after both have run.
fireKeys = botFollowerApplyLaunch(p, fireKeys, aim);
aim = global.botRetAim;

navKeys = botScriptedApplyHolds(p, char, navKeys);

// Dodge an incoming rocket - grounded only, which keeps it out of every
// planned arc, and the only thing that presses JUMP outside the follower.
if (char.onground)
{
    dodge = botReflexRocketDodge(p, p.botSkillReflexTicks, p.botSkillReflexMissChance);
    if (dodge)
        navKeys |= BOT_KEY_JUMP;
}

// Parked: grounded, pressing no direction, and exactly where it was last poll.
// Keyed on the position, not on the follower's state - a bot holding a live
// route it makes no progress on presses nothing and reports nothing.
still = false;
if (char.onground and (navKeys & (BOT_KEY_LEFT | BOT_KEY_RIGHT)) == 0 and p.botScriptedParkedValid)
    still = (char.x == p.botScriptedParkedX and char.y == p.botScriptedParkedY);
p.botScriptedParkedX = char.x;
p.botScriptedParkedY = char.y;
p.botScriptedParkedValid = true;

if (!still)
    p.botScriptedParkedTicks = 0;
else if (!p.botScriptedWantsToEngage and global.botTick >= p.botScriptedRegroupUntil)
    p.botScriptedParkedTicks += 1;
// Standing to fight, or waiting out the regroup hold, pauses the count.

global.botRetAim = aim;
global.botRetAimDist = aimDist;
return navKeys | fireKeys;
