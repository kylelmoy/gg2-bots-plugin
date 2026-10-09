// botScriptedAdvanceRepost(player): ScriptedBot.AdvanceRepost - next re-post
// candidate; once the whole band fails, ask near the bot and ban spots.
var p;
p = argument0;
p.botScriptedRepostSkip = (p.botScriptedRepostSkip + 1) mod BOT_SPOT_TRIES;
if (p.botScriptedRepostSkip != 0)
    exit;
p.botScriptedRepostNearBot = true;
p.botScriptedSpotBanUntil = global.botTick + BOT_SCRIPTED_SPOT_BAN_TICKS;
