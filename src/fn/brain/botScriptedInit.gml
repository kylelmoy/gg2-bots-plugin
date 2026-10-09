// botScriptedInit(player): ScriptedBot's per-bot state, on the Player.
// Stagger is a join counter (botAttach), not the C#'s roster slot.
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
    // Stands in for the C#'s NaN _parkedX/_parkedY.
    botScriptedParkedValid = false;
    botScriptedParkedX = 0;
    botScriptedParkedY = 0;
    botScriptedGoalIsSpot = false;
    // Only while there is a graph (Assign).
    botScriptedHasObjective = false;
    // NavQuery, rebuilt every poll.
    botScriptedQueryTeam = team;
    botScriptedQueryHasIntel = false;
    botScriptedQuerySetupGatesClosed = false;
    botScriptedQueryCanDoubleJump = false;
    botScriptedQueryCanRocketJump = false;
    botScriptedQueryCanStickyJump = false;
    // Stuck-carrier failsafe.
    botScriptedCarrierMarkX = 0;
    botScriptedCarrierMarkY = 0;
    botScriptedCarrierStuckSince = -1;
    botScriptedCarryingSince = -1;
    botScriptedDropIntel = false;
    botScriptedCarrierStuckTicksNow = 0;
    // Last Assign's view; a team or class change re-assigns.
    botScriptedAssignedTeam = -1;
    botScriptedAssignedClass = -1;
    botScriptedNavGeneration = -1;
    botScriptedZoomSentAt = -1000;
}
