// botReflexInBlastBeam(selfX, selfY, px, py, forwardX, forwardY, sideX, sideY):
// BotReflex.InBlastBeam - botInBlastBeam.gml. Is this point inside the volume
// the airblast actually reflects: a BEAM BOT_AIRBLAST_NEAR..BOT_AIRBLAST_REACH
// along the aim and BOT_AIRBLAST_HALFW either side of it (measured off the
// running exe; there IS a near edge). botReflexIncomingProjectile inlines it.
var dx, dy, fwd;
dx = argument2 - argument0;
dy = argument3 - argument1;
fwd = dx * argument4 + dy * argument5;
if (fwd < BOT_AIRBLAST_NEAR or fwd > BOT_AIRBLAST_REACH)
    return false;
return (abs(dx * argument6 + dy * argument7) <= BOT_AIRBLAST_HALFW);
