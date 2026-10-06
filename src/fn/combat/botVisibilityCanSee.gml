// botVisibilityCanSee(viewerChar, subjectChar): BotVisibility.CanSee.
// True for anyone uncloaked, and for a cloaked spy only while its knife
// animation is running (Character.stabbing, set by Revolver User Event 1 and
// cleared by StabAnim's Destroy) in FRONT of the viewer. Behind is
// sign(subject.x - viewer.x) == -sign(viewer.image_xscale): purely horizontal,
// so a spy directly overhead (sign 0) is in front.
// Says nothing about team, hp, range or line of sight.
// The candidate loops (botTargetingFind, botTargetingEnemyWithin,
// botMinesArmed, botCombatStillWorthShootingAt) inline this same test rather
// than paying a call per character; keep them in step with it.
var v, s;
v = argument0;
s = argument1;
if (!s.cloak)
    return true;
if (!s.stabbing)
    return false;
return (sign(s.x - v.x) != -sign(v.image_xscale));
