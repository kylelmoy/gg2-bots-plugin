// botPathSweepBlacklist(player) - BotPathState.SweepBlacklist: drops expired
// bans off the front of the insertion-ordered queue.
//
// `> tick`, so an entry survives until the tick after its expiry - the
// reference's `break` is on the same comparison. Insertion order is expiry
// order because every ban is the same length, which is what makes stopping
// at the first live entry correct.
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
