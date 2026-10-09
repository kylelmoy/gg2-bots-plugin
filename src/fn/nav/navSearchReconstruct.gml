// navSearchReconstruct(start, end, route): NavSearch.Reconstruct - append the
// last search's cameFrom chain to route, start first. False (route cleared)
// if it doesn't reach start. Departure: front-inserts instead of reversing.
var start, at, route, guard, n, base;
start = argument0;
at = argument1;
route = argument2;
n = global.botNavNodeCount;
base = ds_list_size(route);
ds_list_add(route, at);
guard = 0;
while (at != start && guard < n + 2)
{
    at = ds_grid_get(global.navSearchScratch, NAV_SEARCH_FROM, at);
    if (at < 0)
        break;
    ds_list_insert(route, base, at);
    guard += 1;
}
if (ds_list_find_value(route, base) != start)
{
    ds_list_clear(route);
    return false;
}
return true;
