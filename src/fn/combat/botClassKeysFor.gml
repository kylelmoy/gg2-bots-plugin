// botClassKeysFor(player, char, distance, subjectIsAlly): BotClassKeys.For -
// botClassKeys.gml. Which keys this class WANTS at what it is aiming at,
// before BotCombat's fire gates (delay, settle, hold-fire) take ATTACK away.
// Called with no subject too ("a spy re-cloaks, a pyro still reflects"), so
// every branch that would fire at nothing carries its own subject test.
// The spy's keys (BotClassKeys.SpyKeys) are inlined below.
// Reads: botCombatTarget*, botCombatCloakAt, botSkillReflex*, the weapon
// (char.currentWeapon: Flamethrower.readyToBlast/ammoCount,
// Medigun.uberReady, Revolver.readyToStab, Rifle.t/chargeTime) and
// char.cloak/intel/zoomed/aimDirection.
var p, me, dist, isAlly, cls, hasSubject, arcClear, spd, grav, w, keys, incoming, near;
var enemyNear, tgChar, stab, tick;
p = argument0;
me = argument1;
dist = argument2;
isAlly = argument3;
cls = p.class;
w = me.currentWeapon;
tick = global.botTick;

hasSubject = (p.botCombatTargetExists or isAlly);

// Does the lined-up shot have a path to what it is aimed at (BotArc)? Only for
// the two classes whose shot kills them if it goes off next to them.
arcClear = true;
if (p.botCombatTargetExists)
{
    if (cls == CLASS_SOLDIER or cls == CLASS_DEMOMAN)
    {
        spd = botAimBallistics(me);
        grav = global.botRetGravity;
        if (spd > 0)
            arcClear = botArcClear(me, me.aimDirection, spd, grav, p.botCombatTargetX, p.botCombatTargetY);
    }
}

switch (cls)
{
    case CLASS_SOLDIER:
        // Never inside the splash-safe band: a rocket there kills the shooter.
        // (BOT_SPLASH_SAFE is botTargetingClassMinBand of both splash classes.)
        if (hasSubject and arcClear and dist >= BOT_SPLASH_SAFE)
            return BOT_KEY_ATTACK;
        return 0;

    case CLASS_DEMOMAN:
        keys = 0;
        if (hasSubject and arcClear and dist >= BOT_SPLASH_SAFE)
            keys = BOT_KEY_ATTACK;
        // SPECIAL detonates every mine at once; no subject test on purpose.
        near = botMinesArmed(p);
        if (near)
            keys |= BOT_KEY_SPECIAL;
        return keys;

    case CLASS_PYRO:
        keys = 0;
        if (hasSubject and dist <= BOT_FLAME_REACH)
            keys = BOT_KEY_ATTACK;
        // The airblast is a REACTION, ungated by the fire delay, asked of the
        // beam; readyToBlast and the ammo first, since a wasted press costs 40
        // ticks of cooldown.
        if (w != -1)
        {
            if (w.readyToBlast and w.ammoCount >= BOT_CLASS_KEYS_AIRBLAST_AMMO)
            {
                incoming = botReflexIncomingProjectile(p, BOT_AIRBLAST_MIN_TRAVEL,
                                                       p.botSkillReflexTicks, p.botSkillReflexMissChance);
                if (incoming)
                    keys |= BOT_KEY_SPECIAL;
            }
        }
        return keys;

    case CLASS_MEDIC:
        // Needles are the right click; a medic with nobody to heal shoots them,
        // but only at something.
        if (!isAlly)
        {
            if (hasSubject)
                return BOT_KEY_SPECIAL;
            return 0;
        }
        // The beam; the uber is SPECIAL while the beam is held, worth it only
        // with an enemy close enough to matter.
        keys = BOT_KEY_ATTACK;
        if (w != -1)
        {
            if (w.uberReady)
            {
                near = botTargetingEnemyWithin(p, BOT_UBER_RANGE);
                if (near)
                    keys |= BOT_KEY_SPECIAL;
            }
        }
        return keys;

    case CLASS_SPY:
        enemyNear = (p.botCombatTargetKind == BOT_TARGET_KIND_CHARACTER);
        // Cloaked, a real enemy, and the knife is predicted to land: stab.
        // (The cloak clause is a cost guard: a stab and a shot are one key.)
        if (me.cloak and enemyNear and w != -1)
        {
            if (w.readyToStab)
            {
                tgChar = -1;
                if (instance_exists(p.botCombatTargetSlot))
                    tgChar = p.botCombatTargetSlot.object;
                if (tgChar != -1)
                {
                    stab = botStabWindow(me, tgChar);
                    if (stab)
                        return BOT_KEY_ATTACK;
                }
            }
        }
        // cloak == enemyNear is the whole toggle: press exactly when cloaked
        // with company or uncloaked alone. Refused to a carrier, and rate
        // limited so a spy on the boundary does not flicker.
        if (me.cloak == enemyNear and !me.intel)
        {
            if (tick - p.botCombatCloakAt < BOT_CLOAK_PERIOD)
                return 0;
            p.botCombatCloakAt = tick;
            return BOT_KEY_SPECIAL;
        }
        if (me.cloak)
            return 0;
        return BOT_KEY_ATTACK;

    case CLASS_SNIPER:
        // Unscoped, fire at once; scoped, wait for a charge proportional to
        // the range - the Rifle's damage IS its charge.
        if (!hasSubject)
            return 0;
        if (!me.zoomed)
            return BOT_KEY_ATTACK;
        if (w == -1)
            return 0;
        spd = botTargetingClassRange(CLASS_SNIPER);
        if (w.t >= w.chargeTime * min(1, dist / spd))
            return BOT_KEY_ATTACK;
        return 0;
}

// The scout, the heavy, the engineer and Quote: point and shoot - at something.
if (hasSubject)
    return BOT_KEY_ATTACK;
return 0;
