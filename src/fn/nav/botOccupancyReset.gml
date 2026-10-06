// botOccupancyReset(): BotOccupancy.Reset (botOccupancyReset.gml) - drop both
// teams' counts, on a map change. Keys are node indices, which only mean
// anything to one build of the graph.
//
// Also clears every bot's "my route is counted" flag, which the C# leaves to
// ScriptedBot.SetMap: dropping the maps alone leaves each bot believing its
// route is counted, so the next removal declines to decrement and the route
// is then added twice. botNavMapCheck calls this; nothing else needs to.
ds_map_clear(global.botOccupancyRed);
ds_map_clear(global.botOccupancyBlue);
with (Player)
{
    if (variable_local_exists("botPathOccupiedTeam"))
        botPathOccupiedTeam = TEAM_SPECTATOR;
}
