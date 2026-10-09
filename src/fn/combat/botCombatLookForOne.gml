// botCombatLookForOne(player, char, range): BotCombat.LookForOne - target
// search every BOT_TARGET_PERIOD (staggered); if none, a potshot roll at range
// * BOT_POTSHOT_MULT.
var p, me, range, found, tick, pot;
p = argument0;
me = argument1;
range = argument2;
tick = global.botTick;
if (p.botCombatTargetExists)
    exit;
if ((tick + p.botCombatStagger) mod BOT_TARGET_PERIOD != 0)
    exit;

found = botTargetingFind(p, range);
p.botCombatPotshot = false;

if (!found)
{
    pot = botClassProfilePotshots(p.class);
    if (pot)
    {
        if (random(1) < BOT_POTSHOT_CHANCE)
        {
            found = botTargetingFind(p, range * BOT_POTSHOT_MULT);
            p.botCombatPotshot = found;
        }
    }
}

if (!found)
    exit;

p.botCombatTargetExists = true;
p.botCombatTargetKind = global.botRetKind;
p.botCombatTargetSlot = global.botRetSlot;
p.botCombatTargetX = global.botRetX;
p.botCombatTargetY = global.botRetY;
p.botCombatTargetVisible = global.botRetVisible;
p.botCombatTargetAt = tick;
p.botCombatLastSeenAt = tick;
p.botCombatVisible = true;
p.botCombatHoldFire = false;
