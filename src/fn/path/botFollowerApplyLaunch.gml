// botFollowerApplyLaunch(player, fireKeys, aim) - PathFollower.ApplyLaunch:
// applies the follower's launch requests to a bot's outgoing fire keys and
// aim, the one place a route reaches the trigger. Returns the keys in
// global.botRet and the aim (degrees) in global.botRetAim.
//
// The follower owns LEFT / RIGHT / JUMP / DOWN and cannot fire, so a rocket or
// mine jump is married to the combat half's keys here, after both have run.
// The aim is OVERWRITTEN rather than blended (half an aim is a rocket into a
// wall beside the bot's own feet); Begin Step reads aimDirection and the
// trigger bit in the same event, so both are written together.
//
// SPECIAL, not ATTACK, for the detonation: Minegun's User Event 2 detonates
// and User Event 1 would place a second mine. It rides on the same tick as the
// follower's JUMP press.
var p, keys, aim;
p = argument0;
keys = argument1;
aim = argument2;

if (p.botPathRocketFire or p.botPathMineFire)
{
    // Straight down for a MINE, whatever the rocket is doing: it is dropped,
    // so the lip problem does not apply to it.
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
