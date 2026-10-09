// botTargetingAttentionRange(player): BotTargeting.AttentionRange - class
// range, widened to BOT_RETALIATE_RANGE while under fire.
var p, range, hit;
p = argument0;
range = botTargetingClassRange(p.class);
hit = botTargetingUnderFire(p);
if (hit)
    return max(range, BOT_RETALIATE_RANGE);
return range;
