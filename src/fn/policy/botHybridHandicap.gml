// botHybridHandicap(player, keys, aimNet): HybridBot.Handicap - the scripted
// layer's difficulty applied to what the policy pressed. Returns the keys;
// the aim, in wire units, in global.botRetAimNet.
//
// Three BotSkill knobs (botSkill* on the Player, the combat module's), each
// zero at the top tier so tier 5 is the checkpoint as trained and draws
// nothing:
// - the fire delay: no Attack until botSkillFireDelayTicks after the scripted
//   layer acquired its target (botCombatTargetExists, botCombatTargetAt);
// - an aim error, uniform within botSkillPolicyAimErrorDeg, held for
//   botSkillAimInterval controller-driven ticks, added to the output only (the
//   decoder keeps its own aim, so it never accumulates);
// - the hold-fire roll, botSkillHoldFireChance, on the same draw.
// Only Attack is withheld, never Special (an airblast or a detonation that
// arrives late is not a reaction); movement is left alone.
// Draws come from GM8's random() (PORTING.md), not ScriptedBot.Random.
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

// (ushort)(net + error): wraps.
net += pl.botHybridHandicapAim;
net -= floor(net / 65536) * 65536;
global.botRetAimNet = net;
return keys;
