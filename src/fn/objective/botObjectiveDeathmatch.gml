// botObjectiveDeathmatch(player, char, class, targetChar):
// BotObjective.Deathmatch. Returns found (global.botRet); global.botRetX/Y
// (enemy position), botRetAnchorX/Y, botRetSpotMin/SpotMax/SpotHigh,
// botRetUseSpot. targetChar: live target's Character or -1/noone; without one,
// the nearest living enemy. Goal is a spot anchored on the enemy.
var bot, char, cls, foe, myTeam, best, d, dx, dy, selfX, selfY, minBand, range, high;
bot = argument0;
char = argument1;
cls = argument2;
foe = argument3;

global.botRetX = 0;
global.botRetY = 0;
global.botRetAnchorX = 0;
global.botRetAnchorY = 0;
global.botRetSpotMin = 0;
global.botRetSpotMax = 0;
global.botRetSpotHigh = 0;
global.botRetUseSpot = false;

if (foe == noone)
    foe = -1;

if (foe == -1)
{
    myTeam = bot.team;
    selfX = char.x;
    selfY = char.y;
    best = -1;
    with (Character)
    {
        if (id != char)
        {
            if (team != myTeam)
            {
                dx = x - selfX;
                dy = y - selfY;
                d = dx * dx + dy * dy;
                if (best < 0 or d < best)
                {
                    best = d;
                    foe = id;
                }
            }
        }
    }
}

if (foe == -1)
    return false;

minBand = botTargetingClassMinBand(cls);
range = botTargetingClassRange(cls);
high = botClassProfileSpotHigh(cls);

global.botRetX = foe.x;
global.botRetY = foe.y;
global.botRetAnchorX = foe.x;
global.botRetAnchorY = foe.y;
global.botRetSpotMin = max(minBand, 1);
global.botRetSpotMax = range * BOT_SPOT_BAND;
global.botRetSpotHigh = high;
global.botRetUseSpot = true;
return true;
