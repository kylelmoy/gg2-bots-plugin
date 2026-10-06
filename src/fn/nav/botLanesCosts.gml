// botLanesCosts(lane): BotLanes.Costs - the column of global.botLanesCost for
// this lane, to pass to navSearchFind's lane argument; -1 when no lanes are
// derived (route on the graph's own costs - the C#'s null lanes).
//
// Wraps rather than refusing: the caller is a team position and the roster
// is longer than the lane count by design (BotRoles.Lane).
var c;
c = global.botLanesCount;
if (c < 1)
    return -1;
return ((argument0 mod c) + c) mod c;
