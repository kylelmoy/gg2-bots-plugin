// botDifficultySet(tier): change [Bots] Difficulty mid-game (the debug
// overlay's buttons). Every bot's skill knobs are re-derived from the new tier
// - they are read fresh each tick, so the change lands on the bots' next
// decision - and the tier is saved to gg2.ini as the Bots tab saves it. Not in
// the C#, whose difficulty is fixed per server.
var t;
t = max(BOT_TIER_MIN, min(BOT_TIER_MAX, floor(argument0)));
global.botDifficulty = t;
with (Player)
{
    if (!variable_local_exists("botIsBot"))
        continue;
    if (!botIsBot)
        continue;
    botSkillForTier(id, t);
}
ini_open("gg2.ini");
ini_write_real("Bots", "Difficulty", t);
ini_close();
