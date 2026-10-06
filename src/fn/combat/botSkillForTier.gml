// botSkillForTier(player, tier): BotSkill.ForTier - the server's 1-5
// difficulty as a skill (BotSkill.TierSkills: 0.15, 0.30, 0.42, 0.67, 0.95),
// written onto the Player by botSkillFor. The tier is clamped.
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
