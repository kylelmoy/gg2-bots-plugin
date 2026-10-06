// botOccupancyApply(map, player, delta): BotOccupancy.Apply - add delta to the
// count of every edge of player.botPathPath (the bot's installed route, a
// ds_list of nodes) in map.
//
// A count that falls to nothing is deleted rather than left at zero, so the
// map stays the size of what is being walked. ds_map_replace does not insert
// in GM8, hence the exists test before every write.
var map, route, delta, i, size, key, was, had;
map = argument0;
route = argument1.botPathPath;
delta = argument2;
size = ds_list_size(route);
for (i = 1; i < size; i += 1)
{
    key = ds_list_find_value(route, i - 1) * NAV_KEY_STRIDE + ds_list_find_value(route, i);
    had = ds_map_exists(map, key);
    was = delta;
    if (had)
        was += ds_map_find_value(map, key);
    if (was <= 0)
    {
        if (had)
            ds_map_delete(map, key);
    }
    else if (had)
        ds_map_replace(map, key, was);
    else
        ds_map_add(map, key, was);
}
