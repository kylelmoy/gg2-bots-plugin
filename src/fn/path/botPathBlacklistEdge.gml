// botPathBlacklistEdge(player, fromNode, toNode) - BotPathState.BlacklistEdge
// (botBlacklistEdge.gml): bans an edge for BOT_BLACKLIST_TICKS.
//
// An edge already banned is NOT re-armed: a ban runs from when it was first
// imposed, so a bot that keeps failing the same edge cannot extend it for
// ever. Negative nodes are ignored, which makes it safe to call with
// EdgeFrom/EdgeTo when no edge is running.
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
