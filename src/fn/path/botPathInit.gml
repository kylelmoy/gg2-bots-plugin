// botPathInit(player) - BotPathState's constructor: every field, as
// botPath<Field> on the bot's Player. Called once when the bot joins.
//
// Path is a ds_list of node indices. Blacklist is a ds_map whose KEYS are
// the banned edges (navGraphEdgeKey) and whose values are their expiry ticks;
// BlacklistOrder is a ds_queue of the same keys in the order they were
// imposed, so a sweep off the front is the whole expiry mechanism (every ban
// is the same length, so insertion order is expiry order).
//
// OccupiedTeam is TEAM_SPECTATOR for "counted nowhere"; botOccupancy* (nav)
// owns it and nothing else writes it. PlanQuery (the traveller the route was
// planned for) is flattened to botPathPlanQuery<Field>, defaulting to
// default(NavQuery): team 0 (TEAM_RED) and every flag false.
//
// ReplanStagger is the bot's own offset into the re-plan cadence; the
// reference uses the Player's instance id (botPathPlan.gml:53, `player mod
// BOT_REPLAN_TICKS`), which is what this sets. It is taken modulo
// BOT_REPLAN_TICKS at use. NB: at a stagger below 15 BOT_TAKEOFF_PATIENCE is
// unreachable (see botFollowerPlan); the integrator may overwrite it.
var p;
p = argument0;

p.botPathPath = ds_list_create();
p.botPathOccupiedTeam = TEAM_SPECTATOR;
p.botPathPathAt = 0;
p.botPathHasGoal = false;
p.botPathGoalX = 0;
p.botPathGoalY = 0;
p.botPathPathStale = false;
p.botPathArrived = false;
p.botPathArrivedAt = -1;
p.botPathReplanAt = 0;
p.botPathReplanStagger = p.id;
p.botPathPlanFailUntil = 0;
p.botPathEdgeFrom = -1;
p.botPathEdgeTo = -1;
p.botPathStuckTicks = 0;
p.botPathOffPathTicks = 0;
p.botPathLastX = 0;
p.botPathLastY = 0;
p.botPathLastReplanX = 0;
p.botPathLastReplanY = 0;
p.botPathReplanNear = 0;
p.botPathFailFrom = -1;
p.botPathFailTo = -1;
p.botPathFailCount = 0;
p.botPathFlyingEdge = false;
p.botPathJumpHeld = false;
p.botPathAirTicks = 0;
p.botPathTakeoffTicks = 0;
p.botPathRunupsStarted = 0;
p.botPathRunupsEdgeFrom = -1;
p.botPathRunupsEdgeTo = -1;
p.botPathRunupAt = -1;
p.botPathRejumped = false;
p.botPathBlacklist = ds_map_create();
p.botPathBlacklistOrder = ds_queue_create();

// diagnostics
p.botPathReplans = 0;
p.botPathGoalsSet = 0;
p.botPathStuckFires = 0;
p.botPathReposts = 0;
p.botPathOffRouteFires = 0;
p.botPathBlacklistFires = 0;
p.botPathRocketJumps = 0;

// the launch hand-off (botFollowerApplyLaunch reads these)
p.botPathRocketAim = BOT_FOLLOWER_ROCKET_AIM_DEGREES;
p.botPathRocketFire = false;
p.botPathMineFire = false;
p.botPathMineDetonate = false;
p.botPathStickySetup = -1;

p.botPathStickyJumps = 0;
p.botPathDoubleJumps = 0;
p.botPathUnsupportedEdgeTicks = 0;
p.botPathRocketDuds = 0;
p.botPathLaunches = 0;
p.botPathLaunchesUnderspeed = 0;
p.botPathGateColdWeapon = 0;
p.botPathGateTooFast = 0;
p.botPathGateBackwards = 0;
p.botPathGateShort = 0;
p.botPathEdgeUnroutableFires = 0;

p.botPathPlanQueryTeam = TEAM_RED;
p.botPathPlanQueryHasIntel = false;
p.botPathPlanQuerySetupGatesClosed = false;
p.botPathPlanQueryCanDoubleJump = false;
p.botPathPlanQueryCanRocketJump = false;
p.botPathPlanQueryCanStickyJump = false;
