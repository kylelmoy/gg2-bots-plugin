// navGraphTryLoad(path): NavCache.TryLoad + Parse + the NavGraph constructor -
// read <key>.txt and install it as the graph (PORTING.md, "The nav graph in
// memory"). Returns true when a graph is installed; false - having allocated
// nothing and changed no global - when the file is absent, declares another
// NAV_CACHE_VERSION, or does not deserialise to the shape its header promised.
//
// A miss is not an error: a map with no graph is served to humans, and its
// bots fight without walking. The caller must have freed any previous graph
// (navGraphFree) and sets global.botNavMap/Area/Ready itself.
//
// The file is uncompressed (docs/NAVFILES.md), so there is no .txt.gz arm.
// Lines 3 and 4 are GM8's own ds_grid_write format and load natively.
// Success is judged by the dimensions ds_grid_read leaves behind: it is a
// procedure in GM8, not a predicate.
//
// Neither index is in the file, on purpose: both are derived here in one pass
// each, which costs less than the parse that just happened.
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
// Refused rather than adapted: the field layout is what matters, and a reader
// that accepts a graph from another generator trusts numbers about geometry
// that no longer exists.
while (string_char_at(header, string_length(header)) == " ")
    header = string_copy(header, 1, string_length(header) - 1);
if (header != "navgraph " + string(NAV_CACHE_VERSION))
{
    file_text_close(f);
    return false;
}

dims = string_replace_all(file_text_read_string(f), chr(13), "") + " ";
file_text_readln(f);
// Four space-separated integers.
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

// The edge line may be absent: a graph with no edges is a one-grid file.
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

// The header and the payload have to agree, or the columns do not mean what
// the field constants say they mean. NavGraph also refuses a graph past
// navEdgeKey's stride, which would alias two edges onto one key.
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

// navEdgeIndex: per node, the first outgoing edge (-1 if none) and how many.
// The file groups edges by From, so a node's neighbours are one contiguous
// range. An out-of-range From costs that edge, not the graph.
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

// navRowIndex: the first node on each mask row, or -1. Backwards, so the
// LOWEST index on a row is what survives - NodeFromWorld's strict `<`
// tie-break depends on it.
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

// NavSearch's scratch, sized to the graph once (PORTING: one search at a time,
// so it is shared rather than per bot).
global.navSearchScratch = ds_grid_create(NAV_SEARCH_FIELDS, max(nodeCount, 1));
return true;
