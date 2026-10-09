// botPathSweepBlacklist(player) - BotPathState.SweepBlacklist: drops expired
// bans off the queue front. Equal-length bans: insertion order is expiry order.
var p, m, q, key;
p = argument0;
m = p.botPathBlacklist;
q = p.botPathBlacklistOrder;

while (!ds_queue_empty(q))
{
    key = ds_queue_head(q);
    if (ds_map_find_value(m, key) > global.botTick)
        break;
    ds_map_delete(m, key);
    ds_queue_dequeue(q);
}
