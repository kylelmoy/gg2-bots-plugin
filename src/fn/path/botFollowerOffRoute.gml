// botFollowerOffRoute(player, x, y, team, hasIntel, setupGatesClosed,
//                     canDoubleJump, canRocketJump, canStickyJump)
// PathFollower.OffRoute: landed somewhere the route does not go - take the edge
// away if it has failed twice, and re-plan from where the bot actually is.
// Returns no keys.
//
// Not on the first miss (BotPathState.FailCount: many real edges are marginal
// and flown stochastically). ONLY a real edge counts - a deliberate departure
// of the C# from the reference: the (-1,-1) "no edge running" sentinel used to
// reset the count for the real edge and spend the ban on a pair BlacklistEdge
// discards, so a carrier looped two surfaces for 26,000 ticks.
var p, px, py;
p = argument0;
px = argument1;
py = argument2;

p.botPathOffRouteFires += 1;
p.botPathOffPathTicks = 0;

if (p.botPathEdgeFrom >= 0 and p.botPathEdgeTo >= 0)
{
    if (p.botPathEdgeFrom == p.botPathFailFrom and p.botPathEdgeTo == p.botPathFailTo)
    {
        p.botPathFailCount += 1;
    }
    else
    {
        p.botPathFailFrom = p.botPathEdgeFrom;
        p.botPathFailTo = p.botPathEdgeTo;
        p.botPathFailCount = 1;
    }
}

// Banned by the REMEMBERED pair, not the current one: the count can survive a
// sentinel miss, so the current pair may be (-1,-1) when the second real miss
// lands.
if (p.botPathFailCount >= 2 and p.botPathFailFrom >= 0 and p.botPathFailTo >= 0)
{
    botPathBlacklistEdge(p, p.botPathFailFrom, p.botPathFailTo);
    p.botPathFailCount = 0;
}

botFollowerPlan(p, px, py, argument3, argument4, argument5, argument6, argument7, argument8);
return 0;
