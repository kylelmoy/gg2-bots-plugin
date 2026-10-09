// botOccupancyEdgeCount(team): BotOccupancy.EdgeCount - edges with a nonzero
// count for team; 0 for a non-playing team.
if (argument0 == TEAM_RED)
    return ds_map_size(global.botOccupancyRed);
if (argument0 == TEAM_BLUE)
    return ds_map_size(global.botOccupancyBlue);
return 0;
