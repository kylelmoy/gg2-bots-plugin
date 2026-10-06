// botCombatStep(player, char): BotCombat.Step - botCombatUpdate.gml. One tick
// of a bot's combat brain. char is player.object (noone or -1 when dead).
// Returns the keys it wants (ATTACK / SPECIAL only) in global.botRet, the aim
// in degrees in global.botRetAim and the aim distance in global.botRetAimDist
// (0 when not aiming at anything). The caller ORs the keys with the
// follower's; the two cannot conflict.
// The see -> acquire -> aim-settled -> fire chain, every gate read off the
// bot's botSkill* knobs:
//   see      a target is picked on a staggered cadence (botCombatLookForOne)
//   acquire  ignored entirely - not even turned towards - for
//            botSkillAcquireTicks after it was picked
//   aim      the desired direction is re-solved every botSkillAimInterval
//            ticks from a snapshot refreshed every botSkillPerceiveTicks, and
//            the actual aim slews at botSkillTurnRate
//   fire     ATTACK withheld until botSkillFireDelayTicks after acquisition AND
//            the slew has settled, and dropped for an interval on the hold-fire
//            roll. SPECIAL escapes those gates (it is a reaction) except for
//            the medic, whose needles are on it.
// The medic exception: a team-mate to heal (botAllyFind, on the target
// cadence, re-validated every tick) REPLACES the subject, bypasses every gate,
// and is aimed at straight with no lead.
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

// Widened while somebody is shooting at this bot; the search and the keep
// test read the same number.
range = botTargetingAttentionRange(p);

botCombatKeepOrDropTarget(p, me, range);
if (!p.botCombatTargetExists)
{
    if ((tick + p.botCombatStagger) mod BOT_TARGET_PERIOD == 0)
        botCombatLookForOne(p, me, range);
}

// --- the medic exception: a hurt team-mate outranks an enemy ---------------
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
    // Nothing to aim at: face the way the walk goes (only while really moving,
    // BOT_REST_SPEED), and still run the class's keys - a pyro with an empty
    // screen must still be able to reflect a rocket.
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

// The acquire gate returns BEFORE the slew: a slow bot, not a blind one. An
// ally is not acquired.
if (!isAlly and sinceSeen < p.botSkillAcquireTicks)
{
    p.botCombatAttackKeys = 0;
    global.botRetAim = p.botCombatAimDir;
    global.botRetAimDist = 0;
    return 0;
}

if (isAlly)
{
    // Straight at them: the beam has no travel time to lead.
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

// A beam is not a shot: none of the suppression applies to an ally.
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
