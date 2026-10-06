// botStickyReady(char) - StickyModel.Ready: could this character take a sticky
// jump right now. The same shape as botRocketReady: refuse to leave the ground
// rather than leave badly.
//
// `>` and not `>=` on hp: at exactly NAV_SJ_DAMAGE the demoman dies in the
// air. Ammo is checked but a mine already placed is not - that is the
// follower's state (botPathStickySetup). Nested ifs: GM8's `and` does not
// short-circuit and currentWeapon may be -1 (`self`). The weapon kind is asked
// of the weapon itself (docs/departures/path.md).
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
