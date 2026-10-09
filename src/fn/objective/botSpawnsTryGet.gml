// botSpawnsTryGet(team, group, index): SpawnPoints.TryGet - whether the point
// exists (global.botRet); position in global.botRetX/Y (0, 0 on a miss).
// Non-red reads as blue.
var tm, g, k, i, n, seen;
tm = argument0;
g = argument1;
k = argument2;
global.botRetX = 0;
global.botRetY = 0;
if (tm != TEAM_RED)
    tm = TEAM_BLUE;
if (!variable_global_exists("botSpawnsN"))
    return false;
if (g < 0 or g >= BOT_SPAWNS_GROUP_COUNT or k < 0)
    return false;
seen = 0;
n = global.botSpawnsN;
for (i = 0; i < n; i += 1)
{
    if (ds_grid_get(global.botSpawnsGrid, 0, i) == tm)
    {
        if (ds_grid_get(global.botSpawnsGrid, 1, i) == g)
        {
            if (seen == k)
            {
                global.botRetX = ds_grid_get(global.botSpawnsGrid, 2, i);
                global.botRetY = ds_grid_get(global.botSpawnsGrid, 3, i);
                return true;
            }
            seen += 1;
        }
    }
}
return false;
