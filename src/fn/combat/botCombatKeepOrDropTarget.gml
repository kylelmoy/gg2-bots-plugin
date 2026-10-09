// botCombatKeepOrDropTarget(player, char, range): BotCombat.KeepOrDropTarget -
// keeps or drops the target. A potshot keeps the widened band. Sight checked on
// the perceive cadence; unseen for BOT_TARGET_PERIOD * 2 ticks drops it.
var p, me, range, keepRange, ok, tx, ty, tick;
p = argument0;
me = argument1;
range = argument2;
if (!p.botCombatTargetExists)
    exit;
tick = global.botTick;

keepRange = range;
if (p.botCombatPotshot)
    keepRange = range * BOT_POTSHOT_MULT;

ok = botCombatStillWorthShootingAt(p, me);
if (!ok)
{
    botCombatDropTarget(p);
    exit;
}
tx = global.botRetX;
ty = global.botRetY;
p.botCombatTargetX = tx;
p.botCombatTargetY = ty;

if (point_distance(me.x, me.y, tx, ty) > keepRange)
{
    botCombatDropTarget(p);
    exit;
}

if ((tick + p.botCombatStagger) mod p.botSkillPerceiveTicks != 0)
    exit;

if (collision_line_bulletblocking(me.x, me.y, tx, ty))
{
    p.botCombatVisible = false;
    p.botCombatTargetVisible = false;
    if (tick - p.botCombatLastSeenAt > BOT_TARGET_PERIOD * 2)
        botCombatDropTarget(p);
    exit;
}

p.botCombatVisible = true;
p.botCombatTargetVisible = true;
p.botCombatLastSeenAt = tick;
