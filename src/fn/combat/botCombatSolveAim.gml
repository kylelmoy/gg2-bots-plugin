// botCombatSolveAim(player, char, sinceSeen, distance): BotCombat.SolveAim -
// re-solves botCombatAimWant every botSkillAimInterval ticks; never for an
// ally. A heavy that cannot see its character target aims at botSuppressSpot;
// splash classes aim at feet; then spread error and the hold-fire roll.
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
        // Static spot: no lead.
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

// Floor under the target; without it a still target is predicted to keep
// falling.
fl = botAimFloorUnder(aimX, aimY);
want = botAimSolve(me, aimX, aimY, p.botCombatSeeVx, p.botCombatSeeVy, p.botSkillLeadMode, fl);

moving = (abs(p.botCombatSeeVx) > 0.5 or abs(p.botCombatSeeVy) > 0.5);
mult = botClassProfileAimError(cls);
spread = botCombatSpread(p.botSkillAimErrorDeg * mult, p.botSkillAimConeDeg * mult,
                         p.botSkillMoveErrorMultiplier, moving, sinceSeen, dist);

// Uniform, not Gaussian.
p.botCombatAimWant = want + (random(2) - 1) * spread;

// Once per aim interval.
p.botCombatHoldFire = (random(1) < p.botSkillHoldFireChance);
