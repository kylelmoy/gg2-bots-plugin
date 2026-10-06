// botObjectiveTryZoneCentre(point): BotObjective.TryZoneCentre - the middle of a
// control point's capture zone. Returns whether the point has a zone
// (global.botRet); the middle is global.botRetX / global.botRetY.
//
// The middle, not the origin: a CaptureZone's origin is its top-left corner, and
// arrival is only accurate to BOT_ARRIVE_TOL - measured on koth_valley, a bot
// stopped 3px outside the zone and captured nothing. A CaptureZone binds itself to
// a point in its Alarm 0 (`cp = instance_nearest(x, y, ControlPoint)`, or the
// ArenaControlPoint), which its Create runs at once, so `cp` always exists. The
// FIRST zone bound to the point answers, as the C#'s foreach returns the first.
// A point with no zone is not a goal at all.
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
