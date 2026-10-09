// botSpawnsLoad(): SpawnPoints' constructor - reads the map's spawn points from
// global.spawnPointsRed/Blue (offloadSpawnPoints). Call after each map load.
// global.botSpawnsGrid, 4 x global.botSpawnsN: [0] team, [1] group, [2] x, [3]
// y; red groups 0..4 then blue, each in instance order (SpawnPoints' order).
// Bumps global.botSpawnsGen, the map generation keying held spot nodes and
// botGoalSpotReach.
var t, g, i, n, total, xs, ys, cnt, tm;

if (!variable_global_exists("botSpawnsGrid"))
{
    global.botSpawnsGrid = ds_grid_create(4, 1);
    global.botSpawnsGen = 0;
}
global.botSpawnsN = 0;
global.botSpawnsGen += 1;

if (!variable_global_exists("spawnPointsRed"))
    return;
if (!variable_global_exists("spawnPointsBlue"))
    return;

total = 0;
for (g = 0; g < BOT_SPAWNS_GROUP_COUNT; g += 1)
{
    total += ds_list_size(global.spawnPointsRed[0, g]);
    total += ds_list_size(global.spawnPointsBlue[0, g]);
}
ds_grid_resize(global.botSpawnsGrid, 4, max(1, total));

n = 0;
for (t = 0; t < 2; t += 1)
{
    if (t == 0)
        tm = TEAM_RED;
    else
        tm = TEAM_BLUE;
    for (g = 0; g < BOT_SPAWNS_GROUP_COUNT; g += 1)
    {
        if (t == 0)
        {
            xs = global.spawnPointsRed[0, g];
            ys = global.spawnPointsRed[1, g];
        }
        else
        {
            xs = global.spawnPointsBlue[0, g];
            ys = global.spawnPointsBlue[1, g];
        }
        cnt = ds_list_size(xs);
        for (i = 0; i < cnt; i += 1)
        {
            ds_grid_set(global.botSpawnsGrid, 0, n, tm);
            ds_grid_set(global.botSpawnsGrid, 1, n, g);
            ds_grid_set(global.botSpawnsGrid, 2, n, ds_list_find_value(xs, i));
            ds_grid_set(global.botSpawnsGrid, 3, n, ds_list_find_value(ys, i));
            n += 1;
        }
    }
}
global.botSpawnsN = n;
