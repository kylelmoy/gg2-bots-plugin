// botRocketReady(char) - RocketModel.Ready: has this character a rocket to
// jump with, right now. botRocketCapable plus the launcher's refire flag
// (Weapon.readyToShoot; 30-tick refire, four rounds - a real gate). The hp test
// is re-asked because the search only answered it at plan time: a route
// planned at 160 hp is still installed at 35.
var char, ok;
char = argument0;

ok = botRocketCapable(char);
if (!ok)
    return false;

return char.currentWeapon.readyToShoot;
