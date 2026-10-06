// botRolesSpreadX(stagger): BotRoles.SpreadX - the bot's constant lateral goal
// offset, so a team heading for one objective arrives spread along it.
//
// `stagger` is whatever stable small integer the caller identifies the bot by
// (the C# passes the roster slot; the reference a GM8 instance id). Consecutive
// values alternate sides (mod 2) and walk the magnitude round an 11-cycle. It
// must be constant for the bot's life: a spread that changes re-issues the goal.
var s;
s = argument0;
return (((s mod 2) * 2) - 1) * BOT_SPREAD_MAX * (((s * 7) mod 11) / 10);
