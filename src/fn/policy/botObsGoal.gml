// botObsGoal(char): ObservationWriter.WriteGoal (default AgentGoal) - rows
// 204..210 toward botObsEnemy0; run after botObsEnemies.
// dy before dx: checkpoint order. No enemy: rows 204..206 stay 0.
var ch, g, e, dx, dy, d;
ch = argument0;
g = global.botObsGrid;
e = global.botObsEnemy0;
if (e != noone)
{
    dx = e.x - ch.x;
    dy = e.y - ch.y;
    d = sqrt(dx * dx + dy * dy);
    if (d > 0)
    {
        ds_grid_set(g, 0, BOT_OBS_AT_GOAL, dy / d);
        ds_grid_set(g, 0, BOT_OBS_AT_GOAL + 1, dx / d);
    }
    ds_grid_set(g, 0, BOT_OBS_AT_GOAL + 2, min(d / BOT_OBS_POSITION_SCALE, 1));
}
ds_grid_set(g, 0, BOT_OBS_AT_GOAL + 3, 1);
