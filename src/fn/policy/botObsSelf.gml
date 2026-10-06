// botObsSelf(player, char): ObservationWriter.WriteSelf, rows 0..19.
//   0..8   class one-hot (player.class: CLASS_* are PlayerClass ordinals)
//   9      hp / ClassStats.MaxHp
//   10, 11 hspeed / 15, vspeed / 15
//   12     grounded: !place_free(x, y + 1) asked NOW, inside the game's own
//          charSetSolids()/charUnsetSolids() bracket - what Begin Step's
//          obstacleBelow asks, and what the C#'s Collision.PlaceFree on the
//          character's box transcribes. Not `onground`, which is a Begin Step
//          reading and can be a tick stale (the C#'s remark).
//   13, 14 sin, cos of the aim: netAimDirection * 360 / 65536, which is
//          CharacterState.AimDirection exactly (processClientCommands and
//          botPoll both write aimDirection from it)
//   15     ammoCount / MaxAmmo, when the class's weapon has a magazine
//   16     reload: the weapon's alarm[5] / ReloadTime while it runs
//   17     readyToShoot
//   18     refire: the weapon's alarm[0] / RefireTime while it runs
//   19     engineer: nutsNBolts / 100; nobody else's special is observed
// Alarms count frames, which at 60 fps are half-ticks: they are scaled by
// global.delta_factor into the 30 Hz ticks the C#'s timers count.
var pl, ch, g, cls, wpn, ok, grounded, aim, t;
pl = argument0;
ch = argument1;
g = global.botObsGrid;
cls = pl.class;

ds_grid_set(g, 0, BOT_OBS_AT_SELF + cls, 1);
ds_grid_set(g, 0, BOT_OBS_AT_SELF + 9, ch.hp / global.botObsMaxHp[cls]);
ds_grid_set(g, 0, BOT_OBS_AT_SELF + 10, ch.hspeed / BOT_OBS_VELOCITY_SCALE);
ds_grid_set(g, 0, BOT_OBS_AT_SELF + 11, ch.vspeed / BOT_OBS_VELOCITY_SCALE);

grounded = 0;
with (ch)
{
    charSetSolids();
    if (!place_free(x, y + 1))
        grounded = 1;
    charUnsetSolids();
}
ds_grid_set(g, 0, BOT_OBS_AT_SELF + 12, grounded);

aim = degtorad(ch.netAimDirection * 360 / 65536);
ds_grid_set(g, 0, BOT_OBS_AT_SELF + 13, sin(aim));
ds_grid_set(g, 0, BOT_OBS_AT_SELF + 14, cos(aim));

wpn = ch.currentWeapon;
ok = false;
if (wpn > 0)
    ok = instance_exists(wpn);
if (ok)
{
    if (global.botObsMaxAmmo[cls] > 0)
        ds_grid_set(g, 0, BOT_OBS_AT_SELF + 15, wpn.ammoCount / global.botObsMaxAmmo[cls]);
    if (global.botObsReloadTime[cls] > 0)
    {
        t = wpn.alarm[5] * global.delta_factor;
        if (t > 0)
            ds_grid_set(g, 0, BOT_OBS_AT_SELF + 16, t / global.botObsReloadTime[cls]);
    }
    if (wpn.readyToShoot)
        ds_grid_set(g, 0, BOT_OBS_AT_SELF + 17, 1);
    if (global.botObsRefireTime[cls] > 0)
    {
        t = wpn.alarm[0] * global.delta_factor;
        if (t > 0)
            ds_grid_set(g, 0, BOT_OBS_AT_SELF + 18, t / global.botObsRefireTime[cls]);
    }
}

if (cls == CLASS_ENGINEER)
    ds_grid_set(g, 0, BOT_OBS_AT_SELF + 19, ch.nutsNBolts / BOT_OBS_MAX_NUTS);
