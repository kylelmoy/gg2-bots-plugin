// botScriptedPoll(player, char): ScriptedBot.Poll - follower keys
// (LEFT/RIGHT/JUMP/DOWN) ORed with combat keys (ATTACK/SPECIAL, aim). char is
// -1 when dead. Returns keys; aim (degrees) in global.botRetAim, distance in
// global.botRetAimDist.
var p, char, navKeys, fireKeys, aim, aimDist, still, dodge, airJump, rocket;
p = argument0;
char = argument1;

if (char == -1)
{
    // Dead: drop the route and its occupancy.
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

// New life: randomised regroup hold.
if (!p.botScriptedAliveLast)
    p.botScriptedRegroupUntil = global.botTick + floor(random(BOT_REGROUP_TICKS));
p.botScriptedAliveLast = true;

botScriptedUpdateObjective(p, char);

// Query rebuilt from live state each tick. CanStickyJump stays false, as in the
// C#.
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

// Rocket/sticky jumps need keys from both halves.
fireKeys = botFollowerApplyLaunch(p, fireKeys, aim);
aim = global.botRetAim;

navKeys = botScriptedApplyHolds(p, char, navKeys);

// Rocket dodge; grounded only, so never inside a planned arc.
if (char.onground)
{
    dodge = botReflexRocketDodge(p, p.botSkillReflexTicks, p.botSkillReflexMissChance);
    if (dodge)
        navKeys |= BOT_KEY_JUMP;
}

// Parked: grounded, no direction, same position as last poll.
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

global.botRetAim = aim;
global.botRetAimDist = aimDist;
return navKeys | fireKeys;
