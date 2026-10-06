// botScriptedAdvanceRepost(player): ScriptedBot.AdvanceRepost - take the next
// re-post candidate; once the whole ranked band has failed, ask for ground
// near the bot instead and ban spots for a while.
var p;
p = argument0;
p.botScriptedRepostSkip = (p.botScriptedRepostSkip + 1) mod BOT_SPOT_TRIES;
if (p.botScriptedRepostSkip != 0)
    exit;
p.botScriptedRepostNearBot = true;
p.botScriptedSpotBanUntil = global.botTick + BOT_SCRIPTED_SPOT_BAN_TICKS;
