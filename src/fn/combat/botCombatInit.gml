// botCombatInit(player): sets every per-bot field the combat module owns -
// BotCombatState, flattened onto the Player, and the bot's BotSkill for
// global.botDifficulty (botSkillForTier). Called once when the bot joins.
// See docs/combat.md for what each field is.
var p;
p = argument0;

// BotCombatState.Target (a BotTarget), flattened. Slot is the Player instance
// for a character target, the Sentry / Generator instance otherwise.
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

// BotCombatState.AimSubject (a BotTarget), flattened.
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

// The phase into the shared cadences. The C# uses the roster slot; slots
// compact, so this is a join counter instead (any integer is a valid phase).
if (!variable_global_exists("botCombatStaggerNext"))
    global.botCombatStaggerNext = 0;
p.botCombatStagger = global.botCombatStaggerNext;
global.botCombatStaggerNext += 1;

p.botCombatAlly = noone;
p.botCombatSuppressNode = BOT_SUPPRESS_NO_SPOT;
p.botCombatSuppressAt = 0;

botSkillForTier(p, global.botDifficulty);
