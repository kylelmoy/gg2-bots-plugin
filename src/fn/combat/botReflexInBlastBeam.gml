// botReflexInBlastBeam(selfX, selfY, px, py, forwardX, forwardY, sideX, sideY):
// BotReflex.InBlastBeam - is the point in the airblast beam:
// BOT_AIRBLAST_NEAR..REACH along the aim, BOT_AIRBLAST_HALFW either side.
// Inlined in botReflexIncomingProjectile.
var dx, dy, fwd;
dx = argument2 - argument0;
dy = argument3 - argument1;
fwd = dx * argument4 + dy * argument5;
if (fwd < BOT_AIRBLAST_NEAR or fwd > BOT_AIRBLAST_REACH)
    return false;
return (abs(dx * argument6 + dy * argument7) <= BOT_AIRBLAST_HALFW);
