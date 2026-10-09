// botRolesLane(placeInTeam, lanes): BotRoles.Lane - which of `lanes` corridors
// to route down. placeInTeam: index among the bot's own team's bots, not the
// roster.
var place, lanes;
place = argument0;
lanes = argument1;
if (lanes <= 1)
    return 0;
return ((place mod lanes) + lanes) mod lanes;
