// botRocketCapable(char) - RocketModel.Capable: whether the character can take
// rocket-jump edges at all (hp, launcher, ammo; not refire). Departs: weapon
// kind is read off the weapon instance.
// Nested ifs: `and` does not short-circuit; currentWeapon -1 is self.
var char, w;
char = argument0;

if (char.hp <= NAV_RJ_DAMAGE)
    return false;

w = char.currentWeapon;
if (w == -1)
    return false;
if (w.object_index != Rocketlauncher)
    return false;

return w.ammoCount > 0;
