// botAimBallistics(char): BotAim.Ballistics - the bot's model of its class's
// weapon. Returns global.botRet speed (0 = no lead), global.botRetGravity,
// global.botRetDrift (shooter's hspeed for Scattergun/Shotgun/Minigun, else 0).
// Keyed on class.
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
