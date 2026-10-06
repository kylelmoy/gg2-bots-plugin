// botCombatDropTarget(player): BotCombatState.DropTarget - forgets the target
// and everything derived from it (Target, Potshot, AimSubject).
var p;
p = argument0;
p.botCombatTargetExists = false;
p.botCombatTargetKind = BOT_TARGET_KIND_NONE;
p.botCombatTargetSlot = noone;
p.botCombatTargetX = 0;
p.botCombatTargetY = 0;
p.botCombatTargetVisible = false;
p.botCombatPotshot = false;
p.botCombatAimSubjectKind = BOT_TARGET_KIND_NONE;
p.botCombatAimSubjectSlot = noone;
p.botCombatAimSubjectX = 0;
p.botCombatAimSubjectY = 0;
p.botCombatAimSubjectVisible = false;
