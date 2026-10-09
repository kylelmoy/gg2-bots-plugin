// botScriptedSetMap(player): ScriptedBot.SetMap - drop all graph-indexed state:
// route, occupancy, goal, blacklist, objective, re-post and spot-ban counters.
var p;
p = argument0;
botOccupancyRemove(p);
botFollowerSetMap(p);
p.botScriptedHasObjective = false;
p.botScriptedGoalIsSpot = false;
p.botScriptedSpotBanUntil = 0;
p.botScriptedParkedTicks = 0;
p.botScriptedRepostSkip = 0;
p.botScriptedGoalWasRepost = false;
p.botScriptedRepostNearBot = false;
p.botScriptedParkedValid = false;
p.botScriptedNavGeneration = global.botNavGeneration;
