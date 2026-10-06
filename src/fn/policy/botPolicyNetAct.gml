// botPolicyNetAct(n): PolicyNetwork.Act for tier n on the observation in
// global.botObsGrid (1 x 211). Leaves the argmax of each head in
// global.botPolicyNetHead[0..5] (horizontal, jump, down, fire, aim, zoom) and
// the raw logits in the last layer's scratch grid, global.botPolicyNetT[n,
// layers - 1] (row 0 when the layer count is odd, column 0 when even).
//
// Dense layers, ReLU on the hidden ones, raw logits out, argmax per head,
// never over the product - as the C#. The arithmetic is GM8's double where
// the C# is float32: docs/departures/policy.md has what that moves (one
// argmax in 20,000 sampled observations, per tools/convert-policy.js).
//
// HOW, because an interpreted multiply-add loop would cost ~30 ms: every
// layer is a handful of native ds_grid region calls. For a layer with I
// inputs and O outputs, in the scratch grid T (same shape as the weights):
//   1. the input vector goes in as the first column (or row);
//   2. it is replicated across O columns by doubling copies of the filled
//      part (ds_grid_set_grid_region: 1, 2, 4, ... columns; ceil(log2 O) calls);
//   3. T is multiplied cell-wise by the weights (ds_grid_multiply_grid_region,
//      one call), so T[j, i] = x[i] * W[i][j];
//   4. the I rows are summed onto row 0 by halving: rows h-k..h-1 are added
//      onto rows 0..k-1, k = h div 2, until one row is left
//      (ds_grid_add_grid_region; ceil(log2 I) calls). Row 0 is now W'x;
//   5. the bias row is added (one call) and ReLU clamps the O results (the
//      only per-element work: one ds_grid_get, and a ds_grid_set when negative).
// Layers alternate orientation (convert-policy.js lays the weights out so):
// an even layer reads its input down a column and leaves its outputs along
// row 0; an odd layer reads along a row and leaves a column. So the output of
// one layer is already the shape the next one replicates, with no transpose.
//
// Cost, for the shipped 211 -> 64 -> 64 -> 27 network: 58 bulk native calls
// (layer 0: 1 copy + 6 replicate + 1 multiply + 8 halvings + 1 bias = 17;
// layer 1: 1 + 6 + 1 + 6 + 1 = 15; layer 2: 1 + 5 + 1 + 6 + 1 = 14; argmax:
// 6 x (ds_grid_get_max + ds_grid_value_x) = 12) touching about 60,000 cells
// natively, plus 128 ReLU reads and about 64 writes. At GML.md's ~1-2 us per
// interpreted native call and a few ns per native cell, about 0.4-0.7 ms -
// against ~30 ms for the multiply-adds as a loop. botPolicyNetLoadFile times
// it on the live engine at load (policy.log) and that measurement, not this
// estimate, is what the decision budget charges.
var n, layers, L, t, w, b, nin, nout, c, k, h, i, prev, a, hw, m, idx;
n = argument0;
layers = global.botPolicyNetLayers[n];
prev = global.botObsGrid;
for (L = 0; L < layers; L += 1)
{
    t = global.botPolicyNetT[n, L];
    w = global.botPolicyNetW[n, L];
    b = global.botPolicyNetB[n, L];
    nin = global.botPolicyNetIn[n, L];
    nout = global.botPolicyNetOut[n, L];
    if ((L mod 2) == 0)
    {
        // Input down column 0 (rows 0..nin-1), outputs along row 0.
        ds_grid_set_grid_region(t, prev, 0, 0, 0, nin - 1, 0, 0);
        c = 1;
        while (c < nout)
        {
            k = min(c, nout - c);
            ds_grid_set_grid_region(t, t, 0, 0, k - 1, nin - 1, c, 0);
            c += k;
        }
        ds_grid_multiply_grid_region(t, w, 0, 0, nout - 1, nin - 1, 0, 0);
        h = nin;
        while (h > 1)
        {
            k = h div 2;
            ds_grid_add_grid_region(t, t, 0, h - k, nout - 1, h - 1, 0, 0);
            h -= k;
        }
        ds_grid_add_grid_region(t, b, 0, 0, nout - 1, 0, 0, 0);
        if (L < layers - 1)
            for (i = 0; i < nout; i += 1)
                if (ds_grid_get(t, i, 0) < 0)
                    ds_grid_set(t, i, 0, 0);
    }
    else
    {
        // Input along row 0 (columns 0..nin-1), outputs down column 0.
        ds_grid_set_grid_region(t, prev, 0, 0, nin - 1, 0, 0, 0);
        c = 1;
        while (c < nout)
        {
            k = min(c, nout - c);
            ds_grid_set_grid_region(t, t, 0, 0, nin - 1, k - 1, 0, c);
            c += k;
        }
        ds_grid_multiply_grid_region(t, w, 0, 0, nin - 1, nout - 1, 0, 0);
        h = nin;
        while (h > 1)
        {
            k = h div 2;
            ds_grid_add_grid_region(t, t, h - k, 0, h - 1, nout - 1, 0, 0);
            h -= k;
        }
        ds_grid_add_grid_region(t, b, 0, 0, 0, nout - 1, 0, 0);
        if (L < layers - 1)
            for (i = 0; i < nout; i += 1)
                if (ds_grid_get(t, 0, i) < 0)
                    ds_grid_set(t, 0, i, 0);
    }
    prev = t;
}

// Argmax per head. ds_grid_value_x/_y finds the first cell holding the max,
// which is the C#'s "first index strictly greater" on any non-tie.
for (i = 0; i < BOT_POLICY_HEADS; i += 1)
{
    a = global.botPolicyHeadAt[i];
    hw = global.botPolicyHeadWidth[i];
    if (((layers - 1) mod 2) == 0)
    {
        m = ds_grid_get_max(prev, a, 0, a + hw - 1, 0);
        idx = ds_grid_value_x(prev, a, 0, a + hw - 1, 0, m) - a;
    }
    else
    {
        m = ds_grid_get_max(prev, 0, a, 0, a + hw - 1);
        idx = ds_grid_value_y(prev, 0, a, 0, a + hw - 1, m) - a;
    }
    if (idx < 0 or idx >= hw)
        idx = 0;
    global.botPolicyNetHead[i] = idx;
}
