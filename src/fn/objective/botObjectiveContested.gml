// botObjectiveContested(point, team): BotObjective.Contested
// (botPointContested) - an enemy of `team` is on the point or has capture
// progress on it. Locked = never contested. `point`: any ControlPoint-family
// instance. Presence: 0 nobody, 1 only ubered, 2 cappers.
var point, tm, enemyPresence;
point = argument0;
tm = argument1;

if (point == noone or point == -1)
    return false;
if (!instance_exists(point))
    return false;
if (point.locked)
    return false;

if (tm == TEAM_RED)
    enemyPresence = point.bluePresence;
else
    enemyPresence = point.redPresence;

if (enemyPresence > 0)
    return true;

return (point.capping > 0 and point.cappingTeam != -1 and point.cappingTeam != tm);
