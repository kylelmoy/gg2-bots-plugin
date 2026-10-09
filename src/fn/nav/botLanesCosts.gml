// botLanesCosts(lane): BotLanes.Costs - lane's column in global.botLanesCost
// for navSearchFind; -1 when no lanes are derived (the C#'s null). Wraps lane.
var c;
c = global.botLanesCount;
if (c < 1)
    return -1;
return ((argument0 mod c) + c) mod c;
