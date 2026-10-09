// botObjectiveNearestEnemySpawn(team, fromX, fromY):
// BotObjective.NearestEnemySpawn (botEnemySpawn) - the spawn point of `team`'s
// enemy nearest (fromX, fromY). Returns whether one exists (global.botRet);
// point in global.botRetX/Y. First of equals wins.
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
