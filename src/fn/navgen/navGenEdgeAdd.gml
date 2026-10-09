// navGenEdgeAdd(from, to, type, bucket, ticks, cost, gate, takeoff, rejump):
// NavEdgeBuffer.Add - one row of global.navGenEdges, grown by doubling.
var g, e;
g = global.navGenEdges;
e = global.navGenEdgeCount;
if (e >= ds_grid_height(g))
    ds_grid_resize(g, NAV_EDGE_FIELDS, ds_grid_height(g) * 2);
ds_grid_set(g, NAV_EDGE_FROM, e, argument0);
ds_grid_set(g, NAV_EDGE_TO, e, argument1);
ds_grid_set(g, NAV_EDGE_TYPE, e, argument2);
ds_grid_set(g, NAV_EDGE_BUCKET, e, argument3);
ds_grid_set(g, NAV_EDGE_TICKS, e, argument4);
ds_grid_set(g, NAV_EDGE_COST, e, argument5);
ds_grid_set(g, NAV_EDGE_GATE, e, argument6);
ds_grid_set(g, NAV_EDGE_TAKEOFF, e, argument7);
ds_grid_set(g, NAV_EDGE_REJUMP, e, argument8);
global.navGenEdgeCount = e + 1;
