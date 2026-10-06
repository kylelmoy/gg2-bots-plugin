// botOccupancyAdd(player, team): BotOccupancy.Add - add this bot's installed
// route (player.botPathPath) to team's counts, and record the team it was
// counted under in player.botPathOccupiedTeam.
//
// Idempotent, and that is not tidiness: a route is added in one place but
// removed in three, and a count that goes negative makes an edge cheaper the
// more bots are on it. A route of fewer than two nodes counts nothing and
// clears the flag: a flag left set against no route makes the next add a
// no-op and the bot invisible to its team-mates for ever.
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
