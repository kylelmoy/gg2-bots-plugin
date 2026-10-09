// botOccupancyCounts(team): BotOccupancy.Counts - team's counts ds_map for
// navSearchFind's occupancy argument; -1 for a non-playing team. Read-only.
if (argument0 == TEAM_RED)
    return global.botOccupancyRed;
if (argument0 == TEAM_BLUE)
    return global.botOccupancyBlue;
return -1;
