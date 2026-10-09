// navGraphTryLoad(path): NavCache.TryLoad + Parse + NavGraph ctor - install
// <key>.txt as the graph. False (nothing allocated, no global changed) if
// absent, wrong NAV_CACHE_VERSION, or malformed. Caller frees the old graph
// and sets botNavMap/Area/Ready. Lines 3-4 are ds_grid_write strings.
var path, f, header, dims, maskW, maskH, nodeCount, edgeCount, nodes, edges;
var tok, sp, i, ok, edgeStart, rowStart, from, row, line;
path = argument0;

if (!file_exists(path))
    return false;
f = file_text_open_read(path);
if (f < 0)
    return false;

header = string_replace_all(file_text_read_string(f), chr(13), "");
file_text_readln(f);
while (string_char_at(header, string_length(header)) == " ")
    header = string_copy(header, 1, string_length(header) - 1);
if (header != "navgraph " + string(NAV_CACHE_VERSION))
{
    file_text_close(f);
    return false;
}

dims = string_replace_all(file_text_read_string(f), chr(13), "") + " ";
file_text_readln(f);
// maskW maskH nodeCount edgeCount
for (i = 0; i < 4; i += 1)
{
    while (string_char_at(dims, 1) == " ")
        dims = string_delete(dims, 1, 1);
    sp = string_pos(" ", dims);
    if (sp <= 1)
    {
        file_text_close(f);
        return false;
    }
    tok = string_copy(dims, 1, sp - 1);
    dims = string_delete(dims, 1, sp);
    if (string_digits(tok) != tok)
    {
        file_text_close(f);
        return false;
    }
    if (i == 0)
        maskW = real(tok);
    else if (i == 1)
        maskH = real(tok);
    else if (i == 2)
        nodeCount = real(tok);
    else
        edgeCount = real(tok);
}

if (file_text_eof(f))
{
    file_text_close(f);
    return false;
}

nodes = ds_grid_create(NAV_NODE_FIELDS, max(nodeCount, 1));
line = file_text_read_string(f);
file_text_readln(f);
ds_grid_read(nodes, string_replace_all(line, chr(13), ""));

// Edge line may be absent (no edges).
edges = ds_grid_create(NAV_EDGE_FIELDS, max(edgeCount, 1));
if (!file_text_eof(f))
{
    line = string_replace_all(file_text_read_string(f), chr(13), "");
    file_text_readln(f);
    if (line != "")
        ds_grid_read(edges, line);
}
file_text_close(f);
line = "";

// ds_grid_read reports nothing; check the dimensions it left. Also refuse
// nodeCount > NAV_KEY_STRIDE (edge keys would alias).
ok = true;
if (ds_grid_width(nodes) != NAV_NODE_FIELDS || ds_grid_height(nodes) < nodeCount)
    ok = false;
if (edgeCount > 0)
{
    if (ds_grid_width(edges) != NAV_EDGE_FIELDS || ds_grid_height(edges) < edgeCount)
        ok = false;
}
if (nodeCount > NAV_KEY_STRIDE)
    ok = false;
if (!ok)
{
    ds_grid_destroy(nodes);
    ds_grid_destroy(edges);
    return false;
}

// edgeStart: per node, first outgoing edge (-1) and count. Edges are grouped
// by From; an out-of-range From is skipped.
edgeStart = ds_grid_create(2, max(nodeCount, 1));
ds_grid_set_region(edgeStart, 0, 0, 0, max(nodeCount, 1) - 1, -1);
ds_grid_set_region(edgeStart, 1, 0, 1, max(nodeCount, 1) - 1, 0);
for (i = 0; i < edgeCount; i += 1)
{
    from = ds_grid_get(edges, NAV_EDGE_FROM, i);
    if (from < 0 || from >= nodeCount)
        continue;
    if (ds_grid_get(edgeStart, 0, from) < 0)
        ds_grid_set(edgeStart, 0, from, i);
    ds_grid_add(edgeStart, 1, from, 1);
}

// rowStart: first node per mask row, or -1. Backwards so the lowest index
// wins (NodeFromWorld's tie-break relies on it).
rowStart = ds_grid_create(1, maskH + 2);
ds_grid_clear(rowStart, -1);
for (i = nodeCount - 1; i >= 0; i -= 1)
{
    row = ds_grid_get(nodes, NAV_NODE_Y, i);
    if (row >= 0 && row < maskH + 2)
        ds_grid_set(rowStart, 0, row, i);
}

global.botNavNodes = nodes;
global.botNavEdges = edges;
global.botNavNodeCount = nodeCount;
global.botNavEdgeCount = edgeCount;
global.botNavEdgeStart = edgeStart;
global.botNavRowStart = rowStart;
global.botNavMaskW = maskW;
global.botNavMaskH = maskH;

// Shared search scratch, sized to the graph.
global.navSearchScratch = ds_grid_create(NAV_SEARCH_FIELDS, max(nodeCount, 1));
return true;
