// botScriptedSetMap(player): ScriptedBot.SetMap - a new graph. Everything indexed
// by node or edge belongs to the old graph and goes: the route and its
// occupancy, the goal, the blacklist (botFollowerSetMap), the objective, and
// every re-post and spot-ban counter.
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
