// botPathHasPath(player) - BotPathState.HasPath: whether a route is installed.
// Hot callers may read ds_list_size(player.botPathPath) > 0 directly.
return ds_list_size(argument0.botPathPath) > 0;
