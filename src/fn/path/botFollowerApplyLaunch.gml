// botFollowerApplyLaunch(player, fireKeys, aim) - PathFollower.ApplyLaunch:
// merges launch requests into the combat keys; a launch overwrites the aim.
// Returns keys in global.botRet, aim (degrees) in global.botRetAim.
// Detonation is SPECIAL (ATTACK would place a second mine).
var p, keys, aim;
p = argument0;
keys = argument1;
aim = argument2;

if (p.botPathRocketFire or p.botPathMineFire)
{
    // A mine is always aimed straight down.
    if (p.botPathMineFire)
        aim = BOT_FOLLOWER_ROCKET_AIM_DEGREES;
    else
        aim = p.botPathRocketAim;
    keys = keys | BOT_KEY_ATTACK;
}

if (p.botPathMineDetonate)
{
    aim = BOT_FOLLOWER_ROCKET_AIM_DEGREES;
    keys = keys | BOT_KEY_SPECIAL;
}

global.botRetAim = aim;
return keys;
