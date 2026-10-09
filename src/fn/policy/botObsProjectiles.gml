// botObsProjectiles(char): ObservationWriter.WriteProjectiles - rows
// 56..115, four 15-row blocks for the nearest projectiles within 400 px.
// A kind whose nearest instance is out of range is skipped.
//   +0      present
//   +1, +2  (projectile - self) position / 400
//   +3, +4  hspeed / 15, vspeed / 15 (absolute)
//   +5..13  ProjectileKind - 1 one-hot
//   +14     enemy team
var ch, g, cx, cy, lim, found, k, obj, near, d, at, s, i, p;
ch = argument0;
g = global.botObsGrid;
cx = ch.x;
cy = ch.y;
lim = BOT_OBS_PROJECTILE_RADIUS * BOT_OBS_PROJECTILE_RADIUS;
found = 0;
for (k = 0; k < BOT_OBS_PROJ_KINDS; k += 1)
{
    obj = global.botObsProjObj[k];
    if (instance_number(obj) == 0)
        continue;
    near = instance_nearest(cx, cy, obj);
    if (sqr(near.x - cx) + sqr(near.y - cy) > lim)
        continue;
    with (obj)
    {
        d = sqr(x - cx) + sqr(y - cy);
        if (d <= lim)
        {
            // sorted insert; strict < keeps ties stable.
            // No `and`: GM8 doesn't short-circuit.
            at = min(found, BOT_OBS_PROJECTILES);
            while (at > 0)
            {
                if (d < global.botObsProjD[at - 1])
                    at -= 1;
                else
                    break;
            }
            if (at < BOT_OBS_PROJECTILES)
            {
                s = min(found, BOT_OBS_PROJECTILES - 1);
                while (s > at)
                {
                    global.botObsProjD[s] = global.botObsProjD[s - 1];
                    global.botObsProjId[s] = global.botObsProjId[s - 1];
                    global.botObsProjKind[s] = global.botObsProjKind[s - 1];
                    s -= 1;
                }
                global.botObsProjD[at] = d;
                global.botObsProjId[at] = id;
                global.botObsProjKind[at] = k;
                if (found < BOT_OBS_PROJECTILES)
                    found += 1;
            }
        }
    }
}

for (i = 0; i < found; i += 1)
{
    p = global.botObsProjId[i];
    at = BOT_OBS_AT_PROJ + i * BOT_OBS_PROJ_BLOCK;
    ds_grid_set(g, 0, at, 1);
    ds_grid_set(g, 0, at + 1, (p.x - cx) / BOT_OBS_POSITION_SCALE);
    ds_grid_set(g, 0, at + 2, (p.y - cy) / BOT_OBS_POSITION_SCALE);
    ds_grid_set(g, 0, at + 3, p.hspeed / BOT_OBS_VELOCITY_SCALE);
    ds_grid_set(g, 0, at + 4, p.vspeed / BOT_OBS_VELOCITY_SCALE);
    ds_grid_set(g, 0, at + 5 + global.botObsProjKind[i], 1);
    if (p.team != ch.team)
        ds_grid_set(g, 0, at + 14, 1);
}
