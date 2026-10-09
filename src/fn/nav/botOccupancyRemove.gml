// botOccupancyRemove(player): BotOccupancy.Remove - remove the route from the
// counts of player.botPathOccupiedTeam (not the current team). Call before
// botPathPath is cleared.
var p, occupied, map;
p = argument0;
occupied = p.botPathOccupiedTeam;
if (occupied != TEAM_RED && occupied != TEAM_BLUE)
    return;
map = global.botOccupancyRed;
if (occupied == TEAM_BLUE)
    map = global.botOccupancyBlue;
if (ds_list_size(p.botPathPath) >= 2)
    botOccupancyApply(map, p, -1);
p.botPathOccupiedTeam = TEAM_SPECTATOR;
