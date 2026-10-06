// botCombatPerceive(player): BotCombat.Perceive - refreshes the snapshot of
// where the target is and how fast it is going, every botSkillPerceiveTicks,
// and at once on a change of subject - but only while the target is visible
// (botCombatVisible): a bot does not learn where somebody went behind a wall.
// "Change of subject" is the C#'s `AimSubject == Target`, a BotTarget record
// compared by VALUE (kind, slot, x, y, visible), ported as such: a target that
// has moved since the snapshot counts as a new subject.
var p, tick, same, c;
p = argument0;
tick = global.botTick;
same = (p.botCombatAimSubjectKind == p.botCombatTargetKind
        and p.botCombatAimSubjectSlot == p.botCombatTargetSlot
        and p.botCombatAimSubjectX == p.botCombatTargetX
        and p.botCombatAimSubjectY == p.botCombatTargetY
        and p.botCombatAimSubjectVisible == p.botCombatTargetVisible);
if (tick < p.botCombatPerceiveAt and same)
    exit;
if (!p.botCombatVisible)
    exit;

p.botCombatPerceiveAt = tick + p.botSkillPerceiveTicks;
p.botCombatAimSubjectKind = p.botCombatTargetKind;
p.botCombatAimSubjectSlot = p.botCombatTargetSlot;
p.botCombatAimSubjectX = p.botCombatTargetX;
p.botCombatAimSubjectY = p.botCombatTargetY;
p.botCombatAimSubjectVisible = p.botCombatTargetVisible;
p.botCombatSeeX = p.botCombatTargetX;
p.botCombatSeeY = p.botCombatTargetY;

// A sentry and a generator do not move.
p.botCombatSeeVx = 0;
p.botCombatSeeVy = 0;
if (p.botCombatTargetKind == BOT_TARGET_KIND_CHARACTER)
{
    c = p.botCombatTargetSlot.object;
    if (c != -1)
    {
        p.botCombatSeeVx = c.hspeed;
        p.botCombatSeeVy = c.vspeed;
    }
}
