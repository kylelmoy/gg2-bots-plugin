// botObjectiveNearestEnemySpawn(team, fromX, fromY): BotObjective.NearestEnemySpawn
// (botEnemySpawn) - the enemy spawn point nearest a place. `team` is the ASKING
// bot's. Returns whether there is one (global.botRet); the point is
// global.botRetX / global.botRetY.
//
// Nearest-to-the-caller is "the direction the enemy is coming from": on a
// multi-stage map the five groups are scattered across the level. Reads
// botSpawnsLoad's table directly (one pass in SpawnPoints' group/index order,
// strict `<` so the first of equals wins) rather than through
// botSpawnsCount/botSpawnsTryGet, which would make it quadratic.
var tm, fromX, fromY, enemy, best, bx, by, i, n, sx, sy, d;
tm = argument0;
fromX = argument1;
fromY = argument2;

if (tm == TEAM_RED)
    enemy = TEAM_BLUE;
else
    enemy = TEAM_RED;

best = -1;
bx = 0;
by = 0;
n = 0;
if (variable_global_exists("botSpawnsN"))
    n = global.botSpawnsN;
for (i = 0; i < n; i += 1)
{
    if (ds_grid_get(global.botSpawnsGrid, 0, i) != enemy)
        continue;
    sx = ds_grid_get(global.botSpawnsGrid, 2, i);
    sy = ds_grid_get(global.botSpawnsGrid, 3, i);
    d = point_distance(sx, sy, fromX, fromY);
    if (best >= 0 and d >= best)
        continue;
    best = d;
    bx = sx;
    by = sy;
}

global.botRetX = bx;
global.botRetY = by;
return (best >= 0);
