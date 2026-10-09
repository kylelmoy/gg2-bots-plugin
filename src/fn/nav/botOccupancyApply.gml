// botOccupancyApply(map, player, delta): BotOccupancy.Apply - add delta to
// map's count for every edge of player.botPathPath; counts <= 0 are deleted.
// GM8 ds_map_replace does not insert, hence the exists test.
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
