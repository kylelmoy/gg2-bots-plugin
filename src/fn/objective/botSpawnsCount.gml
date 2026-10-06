// botSpawnsCount(team, group): SpawnPoints.Count - how many spawn points a team
// has in a group (0..BOT_SPAWNS_GROUP_COUNT-1). 0 before botSpawnsLoad has run.
// Anything that is not TEAM_RED reads blue, as SpawnPoints.Groups does.
var tm, g, i, n, c;
tm = argument0;
g = argument1;
if (tm != TEAM_RED)
    tm = TEAM_BLUE;
if (!variable_global_exists("botSpawnsN"))
    return 0;
if (g < 0 or g >= BOT_SPAWNS_GROUP_COUNT)
    return 0;
c = 0;
n = global.botSpawnsN;
for (i = 0; i < n; i += 1)
{
    if (ds_grid_get(global.botSpawnsGrid, 0, i) == tm)
    {
        if (ds_grid_get(global.botSpawnsGrid, 1, i) == g)
            c += 1;
    }
}
return c;
