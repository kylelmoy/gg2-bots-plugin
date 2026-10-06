// botOccupancyMap(team): BotOccupancy.Map - one team's ds_map of edge counts
// (navGraphEdgeKey -> how many of its bots have that edge in an installed
// route), or -1 for a team that fields no bots (spectators).
//
// Per team, because the thing being spread out is a team: a blue bot has no
// reason to avoid the route red is walking.
if (argument0 == TEAM_RED)
    return global.botOccupancyRed;
if (argument0 == TEAM_BLUE)
    return global.botOccupancyBlue;
return -1;
