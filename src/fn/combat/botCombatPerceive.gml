// botCombatPerceive(player): BotCombat.Perceive - refreshes the target
// position/velocity snapshot every botSkillPerceiveTicks, or at once on a new
// subject; only while visible. Subject compared by value (kind, slot, x, y,
// visible), as the C# record.
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

// Buildings do not move.
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
