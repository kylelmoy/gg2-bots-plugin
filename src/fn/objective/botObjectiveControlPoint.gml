// botObjectiveControlPoint(char, team, defending): BotObjective.ControlPoint -
// every control-point-family mode (CP, A/D, KotH, Dual KotH, Arena). Returns
// `found` (global.botRet) and the C#'s ref outputs: global.botRetX /
// global.botRetY (the chosen point's zone centre), global.botRetHeld and
// global.botRetContested.
//
// Everyone heads for the nearest unlocked point it WANTS: a defender, one its
// team owns; an attacker, one its team does not own, or one of ours with an
// enemy on it. Preference is a separate accumulator, not a distance penalty (no
// penalty out-weighs every map's widest gap). Failing that the nearest unlocked
// point, and failing that the nearest at all, so a bot is already walking out
// during the 900/1,800-tick pregame lock. Distances are measured to the zone
// centre, as the C# measures them; a point with no zone is skipped.
//
// Game state: ControlPoint.team (-1 = nobody; C# Owned/Team), .locked, and the
// fields botObjectiveContested reads. Points are visited in instance order, the
// C#'s index order being ControlPoints.Place's; ties keep the first (strict `<`).
//
// DUAL KOTH is the one place the mode itself is read: it is won by holding the
// ENEMY's hill, which no entity signature distinguishes from a two-point CP map.
// The mode is DKothHUD, which basicRoomSetup creates for exactly that layout
// (the C#'s GameMode == DualKingOfTheHill). An attacker goes to the enemy's hill
// unless that hill is locked while some point is open (the cross-lock: the
// enemy holds both, so our own hill is the only one in play).
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
