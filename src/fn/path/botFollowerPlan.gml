// botFollowerPlan(player, x, y, team, hasIntel, setupGatesClosed,
//                 canDoubleJump, canRocketJump, canStickyJump)
// PathFollower.Plan (botPathPlan.gml): works out a fresh route from (x, y) and
// installs it. Returns whether a route was found.
//
// The search runs BEFORE the old route is given up, and a failed search
// KEEPS it - a bot whose new goal cannot be planned for keeps walking the last
// route that worked.
//
// The timer is re-armed whatever happens below, and the stagger is ADDED, not
// used as a phase (botPathPlan.gml:53): the interval is somewhere in [45, 89].
// That interval is a hard ceiling on the takeoff budget - a successful re-plan
// frees the route, EdgeFrom goes to -1, and FollowEdge's change-of-edge test
// zeroes TakeoffTicks on the next tick - so at a stagger below 15
// BOT_TAKEOFF_PATIENCE (60) can never be reached.
//
// The anti-thrash check lives here: two re-plans within BOT_THRASH_DIST of
// each other is a bot going round in a circle at one spot, whatever the cause.
//
// This bot's OWN route comes out of the occupancy counts before it searches,
// or it is charged extra for the path it is already walking and the whole team
// churns lanes every re-plan.
var p, px, py, qTeam, qIntel, qSetup, qDJ, qRJ, qSJ, thrash, start, goal, ok;
p = argument0;
px = argument1;
py = argument2;
qTeam = argument3;
qIntel = argument4;
qSetup = argument5;
qDJ = argument6;
qRJ = argument7;
qSJ = argument8;

p.botPathReplanAt = global.botTick + BOT_REPLAN_TICKS
    + (p.botPathReplanStagger mod BOT_REPLAN_TICKS);

if (!p.botPathHasGoal)
    return false;

// Only while a route is installed. A bot with nothing to follow has to keep
// trying.
if (ds_list_size(p.botPathPath) > 0 and global.botTick < p.botPathPlanFailUntil)
    return false;

thrash = point_distance(px, py, p.botPathLastReplanX, p.botPathLastReplanY);

if (thrash < BOT_THRASH_DIST)
    p.botPathReplanNear += 1;
else
    p.botPathReplanNear = 0;

p.botPathLastReplanX = px;
p.botPathLastReplanY = py;

if (p.botPathReplanNear >= 2)
{
    botPathBlacklistEdge(p, p.botPathEdgeFrom, p.botPathEdgeTo);
    p.botPathReplanNear = 0;
}

// Swept here and nowhere else: a re-plan is the only moment a stale ban could
// affect anything.
botPathSweepBlacklist(p);

botOccupancyRemove(p);

start = navGraphNodeFromWorld(px, py);
if (start < 0)
{
    p.botPathPlanFailUntil = global.botTick + BOT_REPLAN_TICKS;
    return false;
}

goal = navGraphNodeFromWorld(p.botPathGoalX, p.botPathGoalY);
if (goal < 0)
{
    p.botPathPlanFailUntil = global.botTick + BOT_REPLAN_TICKS;
    return false;
}

p.botPathReplans += 1;

// NavSearch.Find(start, goal, query, _scratch, Blacklist,
// occupancy?.Counts(query.Team), Lane, Distances?.For(query)) - see
// docs/path.md, "Assumptions about nav", for how each is passed.
ok = navSearchFind(start, goal, qTeam, qIntel, qSetup, qDJ, qRJ, qSJ,
    p.botFollowerScratch, p.botPathBlacklist, true, p.botFollowerLane,
    BOT_FOLLOWER_NAV_PLAN);
if (!ok)
{
    p.botPathPlanFailUntil = global.botTick + BOT_REPLAN_TICKS;
    return false;
}

// Only NOW is the old route given up.
botPathFreePath(p);
ds_list_copy(p.botPathPath, p.botFollowerScratch);

// Recorded with the route: the route is a list of NODES, and the edge each hop
// costed can only be re-derived by asking the search's own question again.
// Asking the LIVE one instead loops (a launcher going cold mid-arc abandons an
// arc already paid for).
p.botPathPlanQueryTeam = qTeam;
p.botPathPlanQueryHasIntel = qIntel;
p.botPathPlanQuerySetupGatesClosed = qSetup;
p.botPathPlanQueryCanDoubleJump = qDJ;
p.botPathPlanQueryCanRocketJump = qRJ;
p.botPathPlanQueryCanStickyJump = qSJ;
p.botPathPathAt = 0;
p.botPathPathStale = false;
p.botPathPlanFailUntil = 0;

// The one place a route is ever added, against the team asking.
botOccupancyAdd(p, qTeam);
return true;
