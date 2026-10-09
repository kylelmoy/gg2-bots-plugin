// botPathBlacklistEdge(player, fromNode, toNode) - BotPathState.BlacklistEdge:
// bans an edge for BOT_BLACKLIST_TICKS. An existing ban is not re-armed;
// negative nodes are ignored.
var p, fromNode, toNode, key;
p = argument0;
fromNode = argument1;
toNode = argument2;

if (fromNode < 0 or toNode < 0)
    return 0;

key = navGraphEdgeKey(fromNode, toNode);

if (ds_map_exists(p.botPathBlacklist, key))
    return 0;

ds_map_add(p.botPathBlacklist, key, global.botTick + BOT_BLACKLIST_TICKS);
ds_queue_enqueue(p.botPathBlacklistOrder, key);
p.botPathBlacklistFires += 1;
return 0;
