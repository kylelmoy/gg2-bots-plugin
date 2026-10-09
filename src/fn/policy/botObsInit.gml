// botObsInit(): the observation's shared state; called once by
// botPolicyNetLoad.
// global.botObsGrid: ds_grid 1 x 211, row i = ObservationWriter column i.
// Per-class stats are ClassStats/WeaponStats constants.
var i, a;
global.botObsGrid = ds_grid_create(1, BOT_OBS_LENGTH);

global.botObsMaxHp[CLASS_SCOUT] = 100;
global.botObsMaxHp[CLASS_SOLDIER] = 160;
global.botObsMaxHp[CLASS_SNIPER] = 120;
global.botObsMaxHp[CLASS_DEMOMAN] = 120;
global.botObsMaxHp[CLASS_MEDIC] = 120;
global.botObsMaxHp[CLASS_ENGINEER] = 120;
global.botObsMaxHp[CLASS_HEAVY] = 200;
global.botObsMaxHp[CLASS_SPY] = 100;
global.botObsMaxHp[CLASS_PYRO] = 120;
global.botObsMaxHp[CLASS_QUOTE] = 140;

// Scattergun, Rocketlauncher, Rifle, Minegun, Medigun, Shotgun, Minigun,
// Revolver, Flamethrower, Blade.
global.botObsMaxAmmo[CLASS_SCOUT] = 6;
global.botObsMaxAmmo[CLASS_SOLDIER] = 4;
global.botObsMaxAmmo[CLASS_SNIPER] = 0;
global.botObsMaxAmmo[CLASS_DEMOMAN] = 8;
global.botObsMaxAmmo[CLASS_MEDIC] = 40;
global.botObsMaxAmmo[CLASS_ENGINEER] = 6;
global.botObsMaxAmmo[CLASS_HEAVY] = 200;
global.botObsMaxAmmo[CLASS_SPY] = 6;
global.botObsMaxAmmo[CLASS_PYRO] = 200;
global.botObsMaxAmmo[CLASS_QUOTE] = 90;
global.botObsReloadTime[CLASS_SCOUT] = 15;
global.botObsReloadTime[CLASS_SOLDIER] = 22;
global.botObsReloadTime[CLASS_SNIPER] = 40;
global.botObsReloadTime[CLASS_DEMOMAN] = 15;
global.botObsReloadTime[CLASS_MEDIC] = 55;
global.botObsReloadTime[CLASS_ENGINEER] = 15;
global.botObsReloadTime[CLASS_HEAVY] = 0;
global.botObsReloadTime[CLASS_SPY] = 45;
global.botObsReloadTime[CLASS_PYRO] = 0;
global.botObsReloadTime[CLASS_QUOTE] = 55;
global.botObsRefireTime[CLASS_SCOUT] = 20;
global.botObsRefireTime[CLASS_SOLDIER] = 30;
global.botObsRefireTime[CLASS_SNIPER] = 40;
global.botObsRefireTime[CLASS_DEMOMAN] = 26;
global.botObsRefireTime[CLASS_MEDIC] = 3;
global.botObsRefireTime[CLASS_ENGINEER] = 20;
global.botObsRefireTime[CLASS_HEAVY] = 2;
global.botObsRefireTime[CLASS_SPY] = 18;
global.botObsRefireTime[CLASS_PYRO] = 1;
global.botObsRefireTime[CLASS_QUOTE] = 5;

// ProjectileKind - 1: Shot, Rocket, Mine, Flame, Needle, Flare, Blade,
// Bubble, Stab. All set `team`; none has a child object.
global.botObsProjObj[0] = Shot;
global.botObsProjObj[1] = Rocket;
global.botObsProjObj[2] = Mine;
global.botObsProjObj[3] = Flame;
global.botObsProjObj[4] = Needle;
global.botObsProjObj[5] = Flare;
global.botObsProjObj[6] = BladeB;
global.botObsProjObj[7] = Bubble;
global.botObsProjObj[8] = StabMask;

for (i = 0; i < BOT_OBS_RAYS; i += 1)
{
    a = i * (2 * pi / BOT_OBS_RAYS);
    global.botObsRayDx[i] = cos(a);
    global.botObsRayDy[i] = sin(a);
}
for (i = 0; i < BOT_OBS_PROJECTILES; i += 1)
{
    global.botObsProjD[i] = 0;
    global.botObsProjId[i] = noone;
    global.botObsProjKind[i] = 0;
}
global.botObsEnemy0 = noone;
global.botObsEnemy0D = -1;
