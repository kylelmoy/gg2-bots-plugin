// navGenMarkReachable(source, hops): NavGraphBuilder.MarkReachable - stamp
// global.navGenSeenAt[v] = a fresh global.navGenSeenStamp for every node within
// `hops` hops of source over the navGenAdjacency snapshot.
var source, hops, stamp, head, tail, hop, endOfHop, u, p, v, adj;
source = argument0;
hops = argument1;
global.navGenSeenStamp += 1;
stamp = global.navGenSeenStamp;
adj = global.navGenAdjTo;
global.navGenSeenAt[source] = stamp;
head = 0;
tail = 0;
global.navGenQueue[tail] = source;
tail += 1;
for (hop = 0; hop < hops; hop += 1)
{
    if (head >= tail)
        break;
    endOfHop = tail;
    while (head < endOfHop)
    {
        u = global.navGenQueue[head];
        head += 1;
        for (p = global.navGenAdjStart[u]; p < global.navGenAdjStart[u + 1]; p += 1)
        {
            v = ds_grid_get(adj, 0, p);
            if (global.navGenSeenAt[v] == stamp)
                continue;
            global.navGenSeenAt[v] = stamp;
            global.navGenQueue[tail] = v;
            tail += 1;
        }
    }
}
