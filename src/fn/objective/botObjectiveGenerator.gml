// botObjectiveGenerator(class, team, defending): BotObjective.Generator - the
// generator branch. Returns `found` (global.botRet) and the C#'s ref outputs:
// global.botRetX / global.botRetY (wx, wy), global.botRetAnchorX / AnchorY,
// global.botRetSpotMin / SpotMax / SpotHigh and global.botRetUseSpot. Fields the
// branch does not set come back as the caller's defaults (0, false).
//
// The objective is to DESTROY a generator - shot from range, never touched - so
// an attacker's goal is a firing position (a spot anchored on it) and a
// defender's is near its own. Exists = instance_exists(GeneratorRed/Blue) (the
// instance is destroyed with the generator). Its middle is the instance's bbox
// centre, the box GM8 itself reports (Generators.BodyBox).
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
