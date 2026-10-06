// botOccupancyCounts(team): BotOccupancy.Counts - one team's counts, as the
// ds_map navSearchFind takes for its occupancy argument, or -1 for a team that
// fields no bots. Read-only to the caller.
//
// Pass -1 instead when occupancy is switched off (global.botOccupancyOn), as
// gg2-server's population manager passes null.
if (argument0 == TEAM_RED)
    return global.botOccupancyRed;
if (argument0 == TEAM_BLUE)
    return global.botOccupancyBlue;
return -1;
