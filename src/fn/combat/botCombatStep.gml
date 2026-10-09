// botCombatStep(player, char): BotCombat.Step - one combat tick. char is noone
// or -1 when dead. Returns keys (ATTACK/SPECIAL) in global.botRet, aim degrees
// in global.botRetAim, aim distance in global.botRetAimDist (0 if none). Gates:
// acquire (botSkillAcquireTicks, no slew), fire (botSkillFireDelayTicks,
// settled, hold-fire). SPECIAL skips the fire gates except for the medic. A
// medic's ally replaces the target, skips every gate, and is aimed at without
// lead.
var p, me, tick, range, isAlly, alive, keys, tx, ty, dist, sinceSeen, settled, canFire, mult, dz, e, a;
p = argument0;
me = argument1;
tick = global.botTick;
global.botRetAim = p.botCombatAimDir;
global.botRetAimDist = 0;

if (me == noone or me == -1)
{
    p.botCombatAttackKeys = 0;
    return 0;
}

// Widened under fire; shared by search and keep test.
range = botTargetingAttentionRange(p);

botCombatKeepOrDropTarget(p, me, range);
if (!p.botCombatTargetExists)
{
    if ((tick + p.botCombatStagger) mod BOT_TARGET_PERIOD == 0)
        botCombatLookForOne(p, me, range);
}

// Medic: a hurt team-mate outranks an enemy.
isAlly = false;
if (p.class == CLASS_MEDIC)
{
    if ((tick + p.botCombatStagger) mod BOT_TARGET_PERIOD == 0)
        p.botCombatAlly = botAllyFind(p, BOT_HEAL_RANGE, false);
    alive = botAllyStillValid(p, p.botCombatAlly);
    if (alive)
        isAlly = true;
    else
        p.botCombatAlly = noone;
}

if (!p.botCombatTargetExists and !isAlly)
{
    // No subject: face the walk, still run class keys (a pyro must reflect).
    if (me.hspeed > BOT_REST_SPEED)
        p.botCombatAimWant = 0;
    else if (me.hspeed < -BOT_REST_SPEED)
        p.botCombatAimWant = 180;
    botCombatSlew(p);
    global.botRetAim = p.botCombatAimDir;
    keys = botClassKeysFor(p, me, 0, false);
    p.botCombatAttackKeys = keys;
    global.botRetAim = p.botCombatAimDir;
    global.botRetAimDist = 0;
    return keys;
}

if (isAlly)
{
    tx = p.botCombatAlly.object.x;
    ty = p.botCombatAlly.object.y;
}
else
{
    tx = p.botCombatTargetX;
    ty = p.botCombatTargetY;
}
dist = point_distance(me.x, me.y, tx, ty);
sinceSeen = tick - p.botCombatTargetAt;

// Acquire gate, before the slew. Allies skip it.
if (!isAlly and sinceSeen < p.botSkillAcquireTicks)
{
    p.botCombatAttackKeys = 0;
    global.botRetAim = p.botCombatAimDir;
    global.botRetAimDist = 0;
    return 0;
}

if (isAlly)
{
    p.botCombatAimX = tx;
    p.botCombatAimY = ty;
    p.botCombatAimWant = point_direction(me.x, me.y, tx, ty);
}
else
{
    botCombatPerceive(p);
    botCombatSolveAim(p, me, sinceSeen, dist);
}
botCombatSlew(p);

global.botRetAim = p.botCombatAimDir;
dz = min(510, point_distance(me.x, me.y, p.botCombatAimX, p.botCombatAimY));

mult = botClassProfileAimSettle(p.class);
e = p.botCombatAimWant - p.botCombatAimDir + 180;
a = e - 360 * floor(e / 360) - 180;
settled = (abs(a) <= BOT_AIM_SETTLE_DEG * mult);

keys = botClassKeysFor(p, me, dist, isAlly);

canFire = (sinceSeen >= p.botSkillAcquireTicks + p.botSkillFireDelayTicks);

// Allies: no fire gates.
if (!isAlly)
{
    if (!canFire or !settled or p.botCombatHoldFire)
    {
        keys &= ~BOT_KEY_ATTACK;
        if (p.class == CLASS_MEDIC)
            keys &= ~BOT_KEY_SPECIAL;
    }
}

p.botCombatAttackKeys = keys;
global.botRetAim = p.botCombatAimDir;
global.botRetAimDist = dz;
return keys;
