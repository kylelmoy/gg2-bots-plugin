// botObjectiveGenerator(class, team, defending): BotObjective.Generator.
// Returns found (global.botRet); global.botRetX/Y, botRetAnchorX/Y,
// botRetSpotMin/SpotMax/SpotHigh, botRetUseSpot (unset fields 0/false).
// Attacker: a firing spot anchored on the enemy generator's bbox centre;
// defender: its own generator.
var cls, tm, defending, want, gen, wx, wy, anchorX, anchorY, spotMin, spotMax, spotHigh, useSpot;
var minBand, range;
cls = argument0;
tm = argument1;
defending = argument2;

wx = 0;
wy = 0;
anchorX = 0;
anchorY = 0;
spotMin = 0;
spotMax = 0;
spotHigh = 0;
useSpot = false;

if (defending)
    want = tm;
else if (tm == TEAM_RED)
    want = TEAM_BLUE;
else
    want = TEAM_RED;

if (want == TEAM_RED)
    gen = GeneratorRed;
else
    gen = GeneratorBlue;

global.botRetUseSpot = false;
global.botRetAnchorX = 0;
global.botRetAnchorY = 0;
global.botRetSpotMin = 0;
global.botRetSpotMax = 0;
global.botRetSpotHigh = 0;
global.botRetX = 0;
global.botRetY = 0;

if (!instance_exists(gen))
    return false;

wx = (gen.bbox_left + gen.bbox_right) / 2;
wy = (gen.bbox_top + gen.bbox_bottom) / 2;

if (!defending)
{
    minBand = botTargetingClassMinBand(cls);
    range = botTargetingClassRange(cls);
    anchorX = wx;
    anchorY = wy;
    spotMin = max(minBand, 1);
    spotMax = range * BOT_SPOT_BAND;
    spotHigh = 0;
    useSpot = true;
}

global.botRetX = wx;
global.botRetY = wy;
global.botRetAnchorX = anchorX;
global.botRetAnchorY = anchorY;
global.botRetSpotMin = spotMin;
global.botRetSpotMax = spotMax;
global.botRetSpotHigh = spotHigh;
global.botRetUseSpot = useSpot;
return true;
