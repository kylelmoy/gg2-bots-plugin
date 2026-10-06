// botObjectiveDeathmatch(player, char, class, targetChar): BotObjective.Deathmatch
// - Team Deathmatch, where the objective is the other team. Returns `found`
// (global.botRet) and the C#'s ref outputs: global.botRetX / global.botRetY
// (the enemy's position), global.botRetAnchorX / AnchorY, global.botRetSpotMin /
// SpotMax / SpotHigh and global.botRetUseSpot.
//
// `targetChar` is the Character of the combat half's live target, or -1/noone:
// the caller resolves "is it alive" (C# `target is { } acquired &&
// world.IsAlive(acquired)`). Without one, the nearest living enemy (C#
// world.NearestEnemies: other players' living characters, any team but ours,
// squared distance, the first of equals in instance order).
//
// A SPOT anchored on the enemy, never its own position: a goal of "walk onto
// the enemy" walks a soldier inside its own minimum band, where BotClassKeys
// refuses to fire, and leaves it there. Both roles hunt; there is nothing to defend.
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

// Nobody to hunt: no goal. A bot alone on the map stands still rather than
// walking to where somebody used to be.
if (foe == -1)
    return false;

minBand = botTargetingClassMinBand(cls);
range = botTargetingClassRange(cls);
high = botClassProfileSpotHigh(cls);

global.botRetX = foe.x;
global.botRetY = foe.y;
global.botRetAnchorX = foe.x;
global.botRetAnchorY = foe.y;
// The generator's band: inside the weapon's reach rather than on its edge,
// floored at the class's own minimum - the line that stops a point-blank standoff.
global.botRetSpotMin = max(minBand, 1);
global.botRetSpotMax = range * BOT_SPOT_BAND;
// The one anchor in the cascade that is an opponent, so the class's own height
// preference is exactly the question to ask.
global.botRetSpotHigh = high;
global.botRetUseSpot = true;
return true;
