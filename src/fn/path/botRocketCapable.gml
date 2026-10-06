// botRocketCapable(char) - RocketModel.Capable: is this character the KIND of
// traveller a rocket-jump edge is for - the question a ROUTE asks (and what
// NavQuery.CanRocketJump is built from every tick), as against
// botRocketReady's "can it fire this tick".
//
// The refire is NOT tested here: a soldier that has just fired answered "I
// cannot rocket jump" for a second, the live query refused every rocket edge,
// and the bot re-planned the long way round. The hp and ammo tests stay - they
// are durable properties of the traveller. `hp > NAV_RJ_DAMAGE` is strictly
// greater, because the damage lands before the bot does.
//
// Nested ifs, not one and-chain: GM8's `and` does not short-circuit, and
// currentWeapon may be -1, which is `self`. WeaponStats.KindFor(class) ==
// Rocketlauncher is asked of the weapon itself (docs/departures/path.md).
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
