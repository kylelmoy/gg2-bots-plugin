// botObjectiveIntel(char, team, defending): BotObjective.Intel - the CTF /
// Invasion branch of the cascade. Returns `found` (global.botRet) and the C#'s ref
// outputs: global.botRetX / global.botRetY (wx, wy, only meaningful when found),
// global.botRetMustTouch, and global.botRetChase - the team whose briefcase
// carrier to run at, or -1 for "no chase" (C# `Team? chase = null`).
//
// Game state, as GG2.Simulation's IntelState names it:
//   HasBase  instance_exists(IntelligenceBaseRed/Blue); Home = its x, y
//   OnField  instance_exists(IntelligenceRed/Blue) - a carried briefcase has no
//            instance (doEventGrabIntel destroys it, doEventDropIntel makes a new
//            one); X, Y = its x, y
//   CarryingIntel  Character.intel
var char, tm, defending, enemy, wx, wy, found, mustTouch, chase;
var ownBase, ownFlag, enemyBase, enemyFlag, ownHasBase, ownOnField, enemyHasBase, enemyOnField;
char = argument0;
tm = argument1;
defending = argument2;

wx = 0;
wy = 0;
found = false;
mustTouch = false;
chase = -1;

if (tm == TEAM_RED)
{
    enemy = TEAM_BLUE;
    ownBase = IntelligenceBaseRed;
    ownFlag = IntelligenceRed;
    enemyBase = IntelligenceBaseBlue;
    enemyFlag = IntelligenceBlue;
}
else
{
    enemy = TEAM_RED;
    ownBase = IntelligenceBaseBlue;
    ownFlag = IntelligenceBlue;
    enemyBase = IntelligenceBaseRed;
    enemyFlag = IntelligenceRed;
}
ownHasBase = instance_exists(ownBase);
ownOnField = instance_exists(ownFlag);
enemyHasBase = instance_exists(enemyBase);
enemyOnField = instance_exists(enemyFlag);

if (char.intel)
{
    // Carrying: get it home. A capture is a collision with the base, so this is
    // the second goal that has to be walked into rather than covered.
    if (ownHasBase)
    {
        wx = ownBase.x;
        wy = ownBase.y;
        found = true;
        mustTouch = true;
    }
}
else if (defending)
{
    // Guard our own flag wherever it currently IS, dropped in the open included.
    if (ownOnField)
    {
        wx = ownFlag.x;
        wy = ownFlag.y;
        found = true;
    }
    else
    {
        // Not on the ground: an enemy is carrying it.
        chase = enemy;
    }
}
else
{
    // Our own flag being carried outranks fetching theirs, for every role.
    if (!ownOnField and ownHasBase)
    {
        chase = enemy;
    }
    else if (enemyOnField)
    {
        wx = enemyFlag.x;
        wy = enemyFlag.y;
        found = true;
        // The one goal that has to be walked into: forbids standoff and spread.
        mustTouch = true;
    }
    else if (enemyHasBase)
    {
        // A team-mate already has theirs: escort the carrier home.
        chase = tm;
    }
}

global.botRetX = wx;
global.botRetY = wy;
global.botRetMustTouch = mustTouch;
global.botRetChase = chase;
return found;
