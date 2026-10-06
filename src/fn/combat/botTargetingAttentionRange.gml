// botTargetingAttentionRange(player): BotTargeting.AttentionRange - how far
// this bot is looking for something to shoot right now: its class range,
// widened to BOT_RETALIATE_RANGE while something is shooting at it. It widens
// the search and the keep test and nothing else.
var p, range, hit;
p = argument0;
range = botTargetingClassRange(p.class);
hit = botTargetingUnderFire(p);
if (hit)
    return max(range, BOT_RETALIATE_RANGE);
return range;
