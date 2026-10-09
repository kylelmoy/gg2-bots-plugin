// botVisibilityCanSee(viewerChar, subjectChar): BotVisibility.CanSee -
// uncloaked, or a cloaked spy stabbing in front of the viewer (horizontal only;
// overhead is front). Ignores team, hp, range, LOS. Inlined in
// botTargetingFind, botTargetingEnemyWithin, botMinesArmed,
// botCombatStillWorthShootingAt; keep in step.
var v, s;
v = argument0;
s = argument1;
if (!s.cloak)
    return true;
if (!s.stabbing)
    return false;
return (sign(s.x - v.x) != -sign(v.image_xscale));
