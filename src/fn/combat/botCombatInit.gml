// botCombatInit(player): sets the combat fields (BotCombatState, flattened onto
// the Player) and BotSkill for global.botDifficulty. Once per join. See
// docs/combat.md.
var p;
p = argument0;

// BotCombatState.Target. Slot: the Player, or the Sentry/Generator instance.
p.botCombatTargetExists = false;
p.botCombatTargetKind = BOT_TARGET_KIND_NONE;
p.botCombatTargetSlot = noone;
p.botCombatTargetX = 0;
p.botCombatTargetY = 0;
p.botCombatTargetVisible = false;

p.botCombatTargetAt = 0;
p.botCombatLastSeenAt = 0;
p.botCombatVisible = false;
p.botCombatPotshot = false;

p.botCombatAimDir = 0;
p.botCombatAimWant = 0;
p.botCombatAimX = 0;
p.botCombatAimY = 0;
p.botCombatPerceiveAt = 0;
p.botCombatAimAt = 0;

// BotCombatState.AimSubject.
p.botCombatAimSubjectKind = BOT_TARGET_KIND_NONE;
p.botCombatAimSubjectSlot = noone;
p.botCombatAimSubjectX = 0;
p.botCombatAimSubjectY = 0;
p.botCombatAimSubjectVisible = false;

p.botCombatSeeX = 0;
p.botCombatSeeY = 0;
p.botCombatSeeVx = 0;
p.botCombatSeeVy = 0;

p.botCombatHoldFire = false;
p.botCombatCloakAt = 0;
p.botCombatAttackKeys = 0;

// Stagger phase: a join counter, not the C#'s roster slot.
if (!variable_global_exists("botCombatStaggerNext"))
    global.botCombatStaggerNext = 0;
p.botCombatStagger = global.botCombatStaggerNext;
global.botCombatStaggerNext += 1;

p.botCombatAlly = noone;
p.botCombatSuppressNode = BOT_SUPPRESS_NO_SPOT;
p.botCombatSuppressAt = 0;

botSkillForTier(p, global.botDifficulty);
