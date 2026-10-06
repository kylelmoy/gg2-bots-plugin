// botPolicyNetFree(): destroy every grid botPolicyNetLoad made (call when
// the server stops; GM8 has no GC). Leaves no tier loaded.
var n, L;
if (!variable_global_exists("botPolicyNetCount"))
    exit;
for (n = 0; n < global.botPolicyNetCount; n += 1)
{
    for (L = 0; L < global.botPolicyNetLayers[n]; L += 1)
    {
        ds_grid_destroy(global.botPolicyNetW[n, L]);
        ds_grid_destroy(global.botPolicyNetB[n, L]);
        ds_grid_destroy(global.botPolicyNetT[n, L]);
    }
}
global.botPolicyNetCount = 0;
if (global.botObsGrid >= 0)
    ds_grid_destroy(global.botObsGrid);
global.botObsGrid = -1;
