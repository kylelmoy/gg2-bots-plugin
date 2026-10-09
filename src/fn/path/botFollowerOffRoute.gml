// botFollowerOffRoute(player, x, y, team, hasIntel, setupGatesClosed,
//                     canDoubleJump, canRocketJump, canStickyJump)
// PathFollower.OffRoute: blacklists the edge on its second failure and re-plans
// from (x, y). Returns 0. Only a real edge counts; (-1,-1) leaves the count.
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

// Ban the remembered pair; the current one may be (-1,-1).
if (p.botPathFailCount >= 2 and p.botPathFailFrom >= 0 and p.botPathFailTo >= 0)
{
    botPathBlacklistEdge(p, p.botPathFailFrom, p.botPathFailTo);
    p.botPathFailCount = 0;
}

botFollowerPlan(p, px, py, argument3, argument4, argument5, argument6, argument7, argument8);
return 0;
