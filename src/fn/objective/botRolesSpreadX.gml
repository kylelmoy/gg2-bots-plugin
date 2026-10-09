// botRolesSpreadX(stagger): BotRoles.SpreadX - the bot's constant lateral goal
// offset. `stagger`: a stable small integer per bot (C# roster slot); must not
// change for the bot's life.
var s;
s = argument0;
return (((s mod 2) * 2) - 1) * BOT_SPREAD_MAX * (((s * 7) mod 11) / 10);
