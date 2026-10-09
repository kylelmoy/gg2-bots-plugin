// botObjectiveIntel(char, team, defending): BotObjective.Intel - CTF/Invasion.
// Returns found (global.botRet); global.botRetX/Y, global.botRetMustTouch, and
// global.botRetChase (team whose carrier to chase, or -1). A carried briefcase
// has no instance.
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
    // Carrying: walk into our base to capture.
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
    // Guard our flag wherever it is.
    if (ownOnField)
    {
        wx = ownFlag.x;
        wy = ownFlag.y;
        found = true;
    }
    else
    {
        // An enemy is carrying it.
        chase = enemy;
    }
}
else
{
    // Our flag being carried outranks fetching theirs.
    if (!ownOnField and ownHasBase)
    {
        chase = enemy;
    }
    else if (enemyOnField)
    {
        wx = enemyFlag.x;
        wy = enemyFlag.y;
        found = true;
        mustTouch = true;
    }
    else if (enemyHasBase)
    {
        // A team-mate has theirs: escort the carrier.
        chase = tm;
    }
}

global.botRetX = wx;
global.botRetY = wy;
global.botRetMustTouch = mustTouch;
global.botRetChase = chase;
return found;
