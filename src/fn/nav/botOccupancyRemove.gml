// botOccupancyRemove(player): BotOccupancy.Remove - take this bot's route back
// out of the counts, against player.botPathOccupiedTeam - the team it was
// counted under - and never the bot's team now: autobalance and a rotation
// re-team bots, and reading the current team would leave the old team's
// counts raised for ever. Call it BEFORE the route (player.botPathPath) is
// cleared; the counts can only be found through it.
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
