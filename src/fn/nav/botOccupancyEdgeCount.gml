// botOccupancyEdgeCount(team): BotOccupancy.EdgeCount - how many edges that
// team currently has anything on (0 for a team that fields no bots).
if (argument0 == TEAM_RED)
    return ds_map_size(global.botOccupancyRed);
if (argument0 == TEAM_BLUE)
    return ds_map_size(global.botOccupancyBlue);
return 0;
