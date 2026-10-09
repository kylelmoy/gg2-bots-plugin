// botHybridHandicap(player, keys, aimNet): HybridBot.Handicap - skill
// handicap on the policy's input. Returns keys; aim (wire units) in
// global.botRetAimNet.
// Fire delay after target acquired; aim error and hold-fire roll redrawn
// every botSkillAimInterval ticks. Only Attack is withheld.
// Departure: draws use GM8 random(), not ScriptedBot.Random.
var pl, keys, net, reacting;
pl = argument0;
keys = argument1;
net = argument2;

pl.botHybridHandicapTicksLeft -= 1;
if (pl.botHybridHandicapTicksLeft <= 0)
{
    pl.botHybridHandicapTicksLeft = pl.botSkillAimInterval;
    pl.botHybridHandicapAim = 0;
    if (pl.botSkillPolicyAimErrorDeg > 0)
        pl.botHybridHandicapAim = round((random(2) - 1) * pl.botSkillPolicyAimErrorDeg * 65536 / 360);
    pl.botHybridHandicapHoldFire = false;
    if (pl.botSkillHoldFireChance > 0)
        pl.botHybridHandicapHoldFire = (random(1) < pl.botSkillHoldFireChance);
}

reacting = false;
if (pl.botCombatTargetExists)
    reacting = (global.botTick - pl.botCombatTargetAt < pl.botSkillFireDelayTicks);
if (reacting or pl.botHybridHandicapHoldFire)
    if ((keys & BOT_KEY_ATTACK) != 0)
        keys -= BOT_KEY_ATTACK;

// wraps, as (ushort)
net += pl.botHybridHandicapAim;
net -= floor(net / 65536) * 65536;
global.botRetAimNet = net;
return keys;
