// botObjectiveControlPoint(char, team, defending): BotObjective.ControlPoint -
// every control-point mode. Returns found (global.botRet); zone centre in
// global.botRetX/Y, plus global.botRetHeld and global.botRetContested. Nearest
// unlocked wanted point (defender: ours; attacker: not ours or contested), else
// nearest unlocked, else nearest. Zoneless points skipped; ties keep the first.
// Dual KotH (DKothHUD): attacker takes the enemy hill unless it is locked while
// another is open.
var char, tm, defending, best, target, bestOpen, openPt, bestAny, anyPt;
var i, cnt, point, hasZone, zx, zy, d, ours, wanted, isContested, enemyHill, wx, wy, held, contested;
char = argument0;
tm = argument1;
defending = argument2;

global.botRetHeld = false;
global.botRetContested = false;

best = -1;
target = noone;
bestOpen = -1;
openPt = noone;
bestAny = -1;
anyPt = noone;

cnt = instance_number(ControlPoint);
for (i = 0; i < cnt; i += 1)
{
    point = instance_find(ControlPoint, i);

    hasZone = botObjectiveTryZoneCentre(point);
    zx = global.botRetX;
    zy = global.botRetY;
    if (!hasZone)
        continue;

    d = point_distance(char.x, char.y, zx, zy);
    ours = (point.team == tm);

    if (defending)
        wanted = ours;
    else
    {
        isContested = botObjectiveContested(point, tm);
        wanted = (!ours or isContested);
    }

    if (bestAny < 0 or d < bestAny)
    {
        bestAny = d;
        anyPt = point;
    }

    if (point.locked)
        continue;

    if (bestOpen < 0 or d < bestOpen)
    {
        bestOpen = d;
        openPt = point;
    }

    if (wanted and (best < 0 or d < best))
    {
        best = d;
        target = point;
    }
}

if (target == noone)
    target = openPt;
if (target == noone)
    target = anyPt;

if (!defending and instance_exists(DKothHUD) and cnt >= 2)
{
    if (tm == TEAM_RED)
        enemyHill = KothBlueControlPoint;
    else
        enemyHill = KothRedControlPoint;
    if (instance_exists(enemyHill))
    {
        enemyHill = enemyHill.id;
        if (!enemyHill.locked or openPt == noone)
            target = enemyHill;
    }
}

if (target == noone)
    return false;

hasZone = botObjectiveTryZoneCentre(target);
wx = global.botRetX;
wy = global.botRetY;
if (!hasZone)
    return false;

held = (target.team == tm and point_distance(char.x, char.y, wx, wy) <= BOT_HOLD_RADIUS);
contested = botObjectiveContested(target, tm);

global.botRetX = wx;
global.botRetY = wy;
global.botRetHeld = held;
global.botRetContested = contested;
return true;
