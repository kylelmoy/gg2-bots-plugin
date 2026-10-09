// botStickyReady(char) - StickyModel.Ready: can sticky jump this tick (hp >
// NAV_SJ_DAMAGE, Minegun ready, ammo). Departs: weapon kind is read off the
// weapon instance.
// Nested ifs: `and` does not short-circuit; currentWeapon -1 is self.
var char, w;
char = argument0;

if (char.hp <= NAV_SJ_DAMAGE)
    return false;

w = char.currentWeapon;
if (w == -1)
    return false;
if (w.object_index != Minegun)
    return false;
if (!w.readyToShoot)
    return false;

return w.ammoCount > 0;
