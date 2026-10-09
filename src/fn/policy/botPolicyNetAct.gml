// botPolicyNetAct(n): PolicyNetwork.Act - tier n on global.botObsGrid;
// argmax per head in global.botPolicyNetHead[0..5], logits in
// global.botPolicyNetT[n, layers - 1].
// Departure: doubles, not float32 (docs/departures/policy.md).
// Each layer in native ds_grid region ops: replicate input by doubling,
// multiply by W, sum rows by halving, add bias, ReLU.
// Layers alternate orientation (even: input column, output row 0; odd: the
// reverse), so no transpose.
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

// first max wins, as the C#
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
