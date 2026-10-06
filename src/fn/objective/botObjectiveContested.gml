// botObjectiveContested(point, team): BotObjective.Contested (botPointContested)
// - an enemy of `team` is on this control point, or has already put progress on it.
// `point` is a ControlPoint-family instance (ControlPoint, KothControlPoint,
// KothRed/BlueControlPoint, ArenaControlPoint, ControlPoint1..5 - all inherit its
// Create, which runs User Event 0 and sets every field read here).
//
// PRESENCE is the signal: ControlPoint's Step recomputes redPresence /
// bluePresence (0 nobody, 1 only ubered, 2 cappers) every step from the
// Characters standing in it, true the frame an enemy steps in, while the meter
// takes a second. The meter is still read, because a capture under way stays
// contested in the moment the zone is empty. A LOCKED point is contested by
// nobody. C#'s `BeingCaptured` is cappingTeam != -1; `Capping` is capping.
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
