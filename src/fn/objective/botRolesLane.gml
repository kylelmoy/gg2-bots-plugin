// botRolesLane(placeInTeam, lanes): BotRoles.Lane - which of `lanes` corridors
// this bot routes down (BotLanes). `placeInTeam` is the bot's position among its
// OWN team's bots in roster order, not anything roster-wide: teams alternate down
// the roster, so a roster index would hand red the even lanes and blue the odd.
var place, lanes;
place = argument0;
lanes = argument1;
if (lanes <= 1)
    return 0;
return ((place mod lanes) + lanes) mod lanes;
