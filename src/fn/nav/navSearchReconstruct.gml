// navSearchReconstruct(start, end, route): NavSearch.Reconstruct - walk the
// last search's cameFrom back from end, filling route (a ds_list, appended to)
// start-first. Returns false - and clears route - when the chain does not
// reach start: a partial route would have a bot walk confidently from
// somewhere it is not standing. (Unreachable by construction; kept because
// the guard is one comparison.)
//
// Front-inserts rather than walking and reversing as the C# does: GM8 has no
// ds_list reverse, and a native insert beats an interpreted copy loop. The
// order it leaves is the same.
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
