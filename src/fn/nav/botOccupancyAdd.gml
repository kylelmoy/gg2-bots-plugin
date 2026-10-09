// botOccupancyAdd(player, team): BotOccupancy.Add - add player.botPathPath to
// team's counts; record the team in player.botPathOccupiedTeam. Idempotent.
// A route under two nodes counts nothing and clears the flag.
var p, team, map, occupied;
p = argument0;
team = argument1;
if (ds_list_size(p.botPathPath) < 2)
{
    p.botPathOccupiedTeam = TEAM_SPECTATOR;
    return;
}
occupied = p.botPathOccupiedTeam;
if (occupied == TEAM_RED || occupied == TEAM_BLUE)
    return;
map = -1;
if (team == TEAM_RED)
    map = global.botOccupancyRed;
else if (team == TEAM_BLUE)
    map = global.botOccupancyBlue;
if (map < 0)
    return;
botOccupancyApply(map, p, 1);
p.botPathOccupiedTeam = team;
