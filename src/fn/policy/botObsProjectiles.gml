// botObsProjectiles(char): ObservationWriter.WriteProjectiles, rows 56..115,
// four blocks of 15 for the four nearest live projectiles within 400 px of
// the character's origin (WorldView.ProjectilesWithin: nearest first, picked
// rather than truncated, squared distance <= 400^2).
//   +0      present
//   +1, +2  (projectile - self) position / 400
//   +3, +4  hspeed / 15, vspeed / 15 (absolute, not relative)
//   +5..13  ProjectileKind - 1 one-hot (global.botObsProjObj)
//   +14     1 when its team is not this character's team
//
// Cost: a kind with no instance costs one instance_number, and a kind whose
// NEAREST instance (instance_nearest, native) is out of range costs one more
// and is skipped whole, since then all of it is. Only a kind with something in
// range is walked, so the interpreted loop runs over the flames of a pyro
// standing beside you, not over every shot on the map.
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
            // Insertion into the sorted prefix; strictly < keeps the earlier
            // one in front. No `and` in the loop test: GM8 evaluates both
            // sides, and botObsProjD[at - 1] at at == 0 is out of range.
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
