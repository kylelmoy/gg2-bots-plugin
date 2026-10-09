// botObjectiveTryZoneCentre(point): BotObjective.TryZoneCentre - whether the
// point has a capture zone (global.botRet); the zone's bbox centre in
// global.botRetX/Y. First bound zone wins.
var point, got, zx, zy;
point = argument0;
got = false;
zx = 0;
zy = 0;
with (CaptureZone)
{
    if (!got)
    {
        if (cp == point)
        {
            zx = (bbox_left + bbox_right) / 2;
            zy = (bbox_top + bbox_bottom) / 2;
            got = true;
        }
    }
}
global.botRetX = zx;
global.botRetY = zy;
return got;
