// botObsEnemies(player, char): ObservationWriter.WriteEnemies, rows 20..55,
// two blocks of 18 for the two nearest living enemies (WorldView.NearestEnemies:
// any live character on another team, by squared distance between origins,
// ties to whoever was found first). Also leaves the nearest in
// global.botObsEnemy0 (noone when there is none) and its squared distance in
// global.botObsEnemy0D, for botObsGoal.
//   +0      present
//   +1, +2  (enemy - self) position / 400
//   +3, +4  (enemy - self) velocity / 15
//   +5..13  enemy class one-hot (a Quote has no column)
//   +14     enemy hp / its class's max
//   +15,+16 sin, cos of the enemy's netAimDirection
//   +17     time since seen: a fixed 0 in layout v2
// No visibility test, as in the C#: a cloaked spy is observed like anyone.
var pl, ch, g, cx, cy, myteam, e0, e1, d0, d1, d, i, e, at, ecls, aim;
pl = argument0;
ch = argument1;
g = global.botObsGrid;
cx = ch.x;
cy = ch.y;
myteam = pl.team;
e0 = noone;
e1 = noone;
d0 = 0;
d1 = 0;
with (Character)
{
    if (id != ch)
    {
        if (player.team != myteam)
        {
            d = sqr(x - cx) + sqr(y - cy);
            if (e0 == noone)
            {
                e0 = id;
                d0 = d;
            }
            else if (d < d0)
            {
                e1 = e0;
                d1 = d0;
                e0 = id;
                d0 = d;
            }
            else if (e1 == noone)
            {
                e1 = id;
                d1 = d;
            }
            else if (d < d1)
            {
                e1 = id;
                d1 = d;
            }
        }
    }
}
global.botObsEnemy0 = e0;
global.botObsEnemy0D = d0;

for (i = 0; i < BOT_OBS_ENEMIES; i += 1)
{
    if (i == 0)
        e = e0;
    else
        e = e1;
    if (e == noone)
        continue;
    at = BOT_OBS_AT_ENEMY + i * BOT_OBS_ENEMY_BLOCK;
    ds_grid_set(g, 0, at, 1);
    ds_grid_set(g, 0, at + 1, (e.x - cx) / BOT_OBS_POSITION_SCALE);
    ds_grid_set(g, 0, at + 2, (e.y - cy) / BOT_OBS_POSITION_SCALE);
    ds_grid_set(g, 0, at + 3, (e.hspeed - ch.hspeed) / BOT_OBS_VELOCITY_SCALE);
    ds_grid_set(g, 0, at + 4, (e.vspeed - ch.vspeed) / BOT_OBS_VELOCITY_SCALE);
    ecls = e.player.class;
    if (ecls >= 0 and ecls < BOT_OBS_CLASSES)
        ds_grid_set(g, 0, at + 5 + ecls, 1);
    ds_grid_set(g, 0, at + 14, e.hp / global.botObsMaxHp[ecls]);
    aim = degtorad(e.netAimDirection * 360 / 65536);
    ds_grid_set(g, 0, at + 15, sin(aim));
    ds_grid_set(g, 0, at + 16, cos(aim));
}
