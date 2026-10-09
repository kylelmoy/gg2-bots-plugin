// botFollowerFloorUnder(x, y) - PathFollower.FloorUnder: whether walkmask
// (CustomMapO) lies under the muzzle for a straight-down blast; scans from the
// muzzle to just past the feet.
var cx, cy, below;
cx = round(argument0);
cy = round(argument1);

for (below = BOT_FOLLOWER_FLOOR_SCAN_FROM; below <= BOT_FOLLOWER_FLOOR_SCAN_TO; below += 1)
{
    if (collision_point(cx, cy + below, CustomMapO, true, true) != noone)
        return true;
}

return false;
