// botFollowerFloorUnder(x, y) - PathFollower.FloorUnder: is there anything
// under the muzzle for a straight-down blast to hit?
//
// The muzzle is 20px below the origin when the aim is straight down, and the
// floor a grounded character stands on is about 24px below it, so the scan
// runs from the muzzle to a little past the feet. Asked at the body's own x,
// because that is where the rocket is created.
//
// CollisionWorld.IsSolidAt is the walkmask only: CustomMapO, precise, at the
// world pixel (it floors into the 6px mask cell exactly as CellOf does).
var cx, cy, below;
cx = round(argument0);
cy = round(argument1);

for (below = BOT_FOLLOWER_FLOOR_SCAN_FROM; below <= BOT_FOLLOWER_FLOOR_SCAN_TO; below += 1)
{
    if (collision_point(cx, cy + below, CustomMapO, true, true) != noone)
        return true;
}

return false;
