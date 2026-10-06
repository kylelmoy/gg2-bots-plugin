// botCountTeams(): players on red (global.botRet) and blue (global.botRetBlue),
// bots and people alike, as GameServer.CountTeams.
var red, blue;
red = 0;
blue = 0;
with (Player)
{
    if (team == TEAM_RED)
        red += 1;
    else if (team == TEAM_BLUE)
        blue += 1;
}
global.botRetBlue = blue;
return red;
