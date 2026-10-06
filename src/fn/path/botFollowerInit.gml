// botFollowerInit(player) - PathFollower's per-bot fields, as botFollower<Field>
// on the Player. Called once when the bot joins.
//
// - botFollowerScratch: the follower's own _scratch list, which the search
//   fills before the route is swapped in (a failed search keeps the old route).
// - botFollowerLane: PathFollower.Lane, this bot's lane costs as nav's
//   navSearchFind takes them (its `laneCostsOrMinus1`), or -1 for the graph's
//   own costs. Set by the integrator (ScriptedBot.ApplyLane); cleared by
//   botFollowerSetMap, because a lane is indexed by edge position and only
//   means anything to one build of a graph.
//
// PathFollower.Distances is not per bot here: the tables are one shared set
// owned by nav, and navSearchFind reads them itself (docs/path.md,
// "Assumptions about nav"). PathFollower.Collision is always the live map.
var p;
p = argument0;
p.botFollowerScratch = ds_list_create();
p.botFollowerLane = -1;
