// botRocketReady(char) - RocketModel.Ready: can rocket jump this tick;
// botRocketCapable plus the launcher's readyToShoot.
var char, ok;
char = argument0;

ok = botRocketCapable(char);
if (!ok)
    return false;

return char.currentWeapon.readyToShoot;
