// botScriptedInit(player): ScriptedBot's own state, on the bot's Player.
//
// The C# constructs a ScriptedBot with a stagger (the roster slot) that both
// halves offset their cadences by; here it is a per-bot counter, which does
// the same job - spreading the objective scans and re-plans over different
// ticks - without changing when somebody else leaves.
var p;
p = argument0;
with (p)
{
    botScriptedRegroupUntil = 0;
    botScriptedAliveLast = false;
    botScriptedRole = 0;
    botScriptedSpreadX = 0;
    botScriptedGoalLocked = false;
    botScriptedSpotBanUntil = 0;
    botScriptedParkedTicks = 0;
    botScriptedWantsToEngage = false;
    botScriptedRepostSkip = 0;
    botScriptedGoalWasRepost = false;
    botScriptedRepostFromX = 0;
    botScriptedRepostFromY = 0;
    botScriptedRepostUntil = 0;
    botScriptedRepostJudged = false;
    botScriptedRepostNearBot = false;
    // _parkedX/_parkedY are NaN in the C# when there is no previous poll.
    botScriptedParkedValid = false;
    botScriptedParkedX = 0;
    botScriptedParkedY = 0;
    botScriptedGoalIsSpot = false;
    // The objective layer exists only while there is a graph (Assign).
    botScriptedHasObjective = false;
    // NavQuery, rebuilt from live state every poll.
    botScriptedQueryTeam = team;
    botScriptedQueryHasIntel = false;
    botScriptedQuerySetupGatesClosed = false;
    botScriptedQueryCanDoubleJump = false;
    botScriptedQueryCanRocketJump = false;
    botScriptedQueryCanStickyJump = false;
    // The stuck-carrier failsafe.
    botScriptedCarrierMarkX = 0;
    botScriptedCarrierMarkY = 0;
    botScriptedCarrierStuckSince = -1;
    botScriptedCarryingSince = -1;
    botScriptedDropIntel = false;
    botScriptedCarrierStuckTicksNow = 0;
    // What Assign last saw, so a team or class change re-assigns.
    botScriptedAssignedTeam = -1;
    botScriptedAssignedClass = -1;
    botScriptedNavGeneration = -1;
    botScriptedZoomSentAt = -1000;
}
