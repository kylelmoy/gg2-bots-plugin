// botSkillForTier(player, tier): BotSkill.ForTier - tier (clamped, 1-5) to a
// skill via BotSkill.TierSkills, applied by botSkillFor.
var t, s;
t = max(BOT_TIER_MIN, min(BOT_TIER_MAX, floor(argument1)));
switch (t - BOT_TIER_MIN)
{
    case 0: s = 0.15; break;
    case 1: s = 0.30; break;
    case 2: s = 0.42; break;
    case 3: s = 0.67; break;
    default: s = 0.95; break;
}
botSkillFor(argument0, s);
