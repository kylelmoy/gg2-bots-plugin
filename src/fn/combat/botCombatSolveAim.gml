// botCombatSolveAim(player, char, sinceSeen, distance): BotCombat.SolveAim -
// recomputes the desired direction every botSkillAimInterval ticks from the
// snapshot. Never called for an ally (the C#'s subjectIsAlly is false here).
//  - suppression: a heavy holding a character it cannot see (botCombatVisible
//    false - the LIVE flag) aims at botSuppressSpot's node instead, refreshed
//    on its own BOT_TARGET_PERIOD clock, with the snapshot velocity zeroed;
//  - splash classes with botSkillSplashAim aim BOT_FEET_OFFSET lower at a
//    grounded character;
//  - botAimSolve with the floor under the aim point, then a uniform
//    [-1, 1] * botCombatSpread error, and the hold-fire roll for this interval.
var p, me, sinceSeen, dist, tick, aimX, aimY, cls, sup, foe, c, fl, want, mult, moving, spread;
p = argument0;
me = argument1;
sinceSeen = argument2;
dist = argument3;
tick = global.botTick;
if (tick < p.botCombatAimAt)
    exit;
p.botCombatAimAt = tick + p.botSkillAimInterval;
cls = p.class;

aimX = p.botCombatSeeX;
aimY = p.botCombatSeeY;

sup = false;
if (!p.botCombatVisible and p.botCombatTargetKind == BOT_TARGET_KIND_CHARACTER and global.botNavReady)
    sup = botClassProfileSuppresses(cls);
if (sup)
{
    if (tick >= p.botCombatSuppressAt)
    {
        p.botCombatSuppressAt = tick + BOT_TARGET_PERIOD;
        foe = TEAM_RED;
        if (p.team == TEAM_RED)
            foe = TEAM_BLUE;
        p.botCombatSuppressNode = botSuppressSpot(me, p.botCombatSeeX, p.botCombatSeeY, foe);
    }
    if (p.botCombatSuppressNode >= 0)
    {
        botSuppressCentre(p.botCombatSuppressNode);
        aimX = global.botRetX;
        aimY = global.botRetY;
        // A doorway is not moving: do not lead it by a dead man's velocity.
        p.botCombatSeeVx = 0;
        p.botCombatSeeVy = 0;
    }
}
else
    p.botCombatSuppressNode = BOT_SUPPRESS_NO_SPOT;

if (p.botCombatTargetKind == BOT_TARGET_KIND_CHARACTER and p.botSkillSplashAim)
{
    if (cls == CLASS_SOLDIER or cls == CLASS_DEMOMAN)
    {
        c = p.botCombatTargetSlot.object;
        if (c != -1)
        {
            if (c.onground)
                aimY += BOT_FEET_OFFSET;
        }
    }
}

p.botCombatAimX = aimX;
p.botCombatAimY = aimY;

// The floor under the TARGET, and it is load-bearing: without it a target
// standing still is predicted to keep falling and the bot aims into the ground.
fl = botAimFloorUnder(aimX, aimY);
want = botAimSolve(me, aimX, aimY, p.botCombatSeeVx, p.botCombatSeeVy, p.botSkillLeadMode, fl);

moving = (abs(p.botCombatSeeVx) > 0.5 or abs(p.botCombatSeeVy) > 0.5);
mult = botClassProfileAimError(cls);
spread = botCombatSpread(p.botSkillAimErrorDeg * mult, p.botSkillAimConeDeg * mult,
                         p.botSkillMoveErrorMultiplier, moving, sinceSeen, dist);

// Uniform, not Gaussian (Quake III's crandom()).
p.botCombatAimWant = want + (random(2) - 1) * spread;

// Rolled once per aim interval: withholds a burst rather than stuttering.
p.botCombatHoldFire = (random(1) < p.botSkillHoldFireChance);
