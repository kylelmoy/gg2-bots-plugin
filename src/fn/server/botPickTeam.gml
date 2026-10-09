// botPickTeam(red, blue): BotPopulation.PickTeam - the smaller team, a tie at
// random.
if (argument0 < argument1)
    return TEAM_RED;
if (argument1 < argument0)
    return TEAM_BLUE;
return choose(TEAM_RED, TEAM_BLUE);
