// botFollowerPlan(player, x, y, team, hasIntel, setupGatesClosed,
//                 canDoubleJump, canRocketJump, canStickyJump)
// PathFollower.Plan: searches from (x, y) and installs the route; a failed
// search keeps the old one. Returns whether a route was found.
// Re-plan interval is BOT_REPLAN_TICKS + stagger mod BOT_REPLAN_TICKS; it caps
// TakeoffTicks, so a stagger below 15 never reaches BOT_TAKEOFF_PATIENCE.
var p, px, py, qTeam, qIntel, qSetup, qDJ, qRJ, qSJ, thrash, start, goal, ok, occ, table;
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

// Fail backoff only while a route is installed.
if (ds_list_size(p.botPathPath) > 0 and global.botTick < p.botPathPlanFailUntil)
    return false;

// Anti-thrash: repeated re-plans at one spot blacklist the current edge.
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

botPathSweepBlacklist(p);

// Own route off the counts so the search does not charge for it.
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

// NavSearch.Find(start, goal, query, _scratch, Blacklist, occupancy, Lane,
// Distances)
occ = -1;
if (global.botOccupancyOn)
    occ = botOccupancyCounts(qTeam);
table = navDistFor(qTeam, qIntel, qSetup, qDJ, qRJ, qSJ);
ok = navSearchFind(start, goal, qTeam, qIntel, qSetup, qDJ, qRJ, qSJ,
    p.botFollowerScratch, p.botPathBlacklist, occ, p.botFollowerLane, table,
    BOT_FOLLOWER_NAV_PLAN);
if (!ok)
{
    p.botPathPlanFailUntil = global.botTick + BOT_REPLAN_TICKS;
    return false;
}

botPathFreePath(p);
ds_list_copy(p.botPathPath, p.botFollowerScratch);

// The plan's query; botFollowerTryFindEdge resolves hops against it.
p.botPathPlanQueryTeam = qTeam;
p.botPathPlanQueryHasIntel = qIntel;
p.botPathPlanQuerySetupGatesClosed = qSetup;
p.botPathPlanQueryCanDoubleJump = qDJ;
p.botPathPlanQueryCanRocketJump = qRJ;
p.botPathPlanQueryCanStickyJump = qSJ;
p.botPathPathAt = 0;
p.botPathPathStale = false;
p.botPathPlanFailUntil = 0;

botOccupancyAdd(p, qTeam);
return true;
