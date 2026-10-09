// botOccupancyReset(): BotOccupancy.Reset - clear both teams' counts on map
// change.
// Departure: also resets every bot's botPathOccupiedTeam (ScriptedBot.SetMap in
// C#).
ds_map_clear(global.botOccupancyRed);
ds_map_clear(global.botOccupancyBlue);
with (Player)
{
    if (variable_local_exists("botPathOccupiedTeam"))
        botPathOccupiedTeam = TEAM_SPECTATOR;
}
