// botObsGoal(char): ObservationWriter.WriteGoal for the default AgentGoal,
// rows 204..210 - the nearest enemy botObsEnemies found:
//   204, 205  dy / d, dx / d (dy FIRST: the order every checkpoint reads)
//   206       min(d / 400, 1)
//   207..210  goal kind one-hot; the default kind 0
// With no enemy the first three stay 0. Run after botObsEnemies.
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
