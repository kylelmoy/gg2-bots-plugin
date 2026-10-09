// botOccupancyMap(team): BotOccupancy.Map - team's ds_map navGraphEdgeKey ->
// bot count on that edge; -1 for a non-playing team.
if (argument0 == TEAM_RED)
    return global.botOccupancyRed;
if (argument0 == TEAM_BLUE)
    return global.botOccupancyBlue;
return -1;
