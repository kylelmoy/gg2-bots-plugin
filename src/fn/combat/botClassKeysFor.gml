// botClassKeysFor(player, char, distance, subjectIsAlly): BotClassKeys.For -
// the keys this class wants, before BotCombat's fire gates. May be called with
// no subject, so each firing branch tests for one. BotClassKeys.SpyKeys
// inlined.
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

// BotArc: soldier/demoman need a clear path for the shot.
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
        // BOT_SPLASH_SAFE: own-blast band.
        if (hasSubject and arcClear and dist >= BOT_SPLASH_SAFE)
            return BOT_KEY_ATTACK;
        return 0;

    case CLASS_DEMOMAN:
        keys = 0;
        if (hasSubject and arcClear and dist >= BOT_SPLASH_SAFE)
            keys = BOT_KEY_ATTACK;
        // Detonates every mine; no subject test.
        near = botMinesArmed(p);
        if (near)
            keys |= BOT_KEY_SPECIAL;
        return keys;

    case CLASS_PYRO:
        keys = 0;
        if (hasSubject and dist <= BOT_FLAME_REACH)
            keys = BOT_KEY_ATTACK;
        // Airblast: a reaction, ungated by fire delay; a wasted press costs 40
        // ticks.
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
        // Needles (no ally): only at a subject.
        if (!isAlly)
        {
            if (hasSubject)
                return BOT_KEY_SPECIAL;
            return 0;
        }
        // Beam; uber only with an enemy near.
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
        // Cloaked: stab when the knife will land.
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
        // Toggle cloak when cloak == enemyNear; never a carrier; rate limited.
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
        // Scoped: wait for a charge proportional to range.
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

// Scout, heavy, engineer, Quote.
if (hasSubject)
    return BOT_KEY_ATTACK;
return 0;
