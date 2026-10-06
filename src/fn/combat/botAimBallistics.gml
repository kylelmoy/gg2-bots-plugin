// botAimBallistics(char): BotAim.Ballistics - botWeaponBallistics.gml.
// The bot's MODEL of the weapon its class carries, not the weapon: tuned
// numbers the aim solver flies. Returns
//   global.botRet         Speed (0 = do not lead: the Rifle, the Medigun)
//   global.botRetGravity  Gravity
//   global.botRetDrift    Drift: the shooter's own hspeed, only for the three
//                         weapons whose shots inherit it (Scattergun, Shotgun,
//                         Minigun)
// Keyed on the CLASS (char.player.class), as the C# is, not on the weapon
// object as the reference was.
var c, cls, spd, grav;
c = argument0;
cls = c.player.class;
spd = 0;
grav = 0;
switch (cls)
{
    case CLASS_SCOUT:
    case CLASS_ENGINEER:
        spd = 13; grav = 0.15; break;
    case CLASS_HEAVY:
        spd = 12.5; grav = 0.15; break;
    case CLASS_SPY:
        spd = 21; grav = 0.15; break;
    case CLASS_SOLDIER:
        spd = 12; grav = 0; break;
    case CLASS_DEMOMAN:
        spd = 12; grav = 0.2; break;
    case CLASS_PYRO:
        spd = 8.25; grav = 0.15; break;
    case CLASS_QUOTE:
        spd = 10; grav = 0; break;
}
global.botRetGravity = grav;
global.botRetDrift = 0;
if (cls == CLASS_SCOUT or cls == CLASS_ENGINEER or cls == CLASS_HEAVY)
    global.botRetDrift = c.hspeed;
global.botRet = spd;
