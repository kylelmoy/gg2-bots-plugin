// botPolicyNetLoadFile(path, label): PolicyNetwork.Load - load a converted
// checkpoint as tier global.botPolicyNetCount; returns its index, or -1 if
// refused.
// Departure: adds a self-test against the file's test vector and a timed
// initial cost (global.botPolicyNetCost[n], us); simulation stamp not
// checked.
// Sets global.botPolicyNet{Label,Uuid,Repeat,Layers,Trained,In,Out,W,B,T,
// Cost} for tier n.
var f, s, why, n, i, L, layers, nin, nout, prevOut, w, b, t, grids, list, p, c, test, logits, last, err, e, v, count, t0, elapsed, heads;

n = global.botPolicyNetCount;
why = "";
grids = ds_list_create();

f = file_text_open_read(argument0);
for (i = 0; i < 13; i += 1)
{
    global.botPolicyNetLine[i] = file_text_read_string(f);
    file_text_readln(f);
}

if (global.botPolicyNetLine[0] != "gg2policy")
    why = "not a converted policy file";
else if (real(global.botPolicyNetLine[1]) != BOT_POLICY_FORMAT)
    why = "file format " + global.botPolicyNetLine[1] + ", this plugin reads " + string(BOT_POLICY_FORMAT);
else if (real(global.botPolicyNetLine[5]) != BOT_POLICY_ACTION_ENCODING)
    why = "policy action encoding v" + global.botPolicyNetLine[5] + " against this port's v" + string(BOT_POLICY_ACTION_ENCODING);
else if (real(global.botPolicyNetLine[6]) != BOT_POLICY_OBS_LAYOUT)
    why = "policy observation layout v" + global.botPolicyNetLine[6] + " against this port's v" + string(BOT_POLICY_OBS_LAYOUT);
else if (global.botPolicyNetLine[7] != "3,2,2,3,15,2")
    why = "policy head shape [" + global.botPolicyNetLine[7] + "] against this port's [3,2,2,3,15,2]";
else if (real(global.botPolicyNetLine[8]) != BOT_OBS_LENGTH)
    why = "policy wants " + global.botPolicyNetLine[8] + " observation floats, this port writes " + string(BOT_OBS_LENGTH);
else if (real(global.botPolicyNetLine[9]) < 1)
    why = "action repeat " + global.botPolicyNetLine[9] + " is not positive";

layers = real(global.botPolicyNetLine[12]);
if (why == "")
    if (layers < 1 or layers > BOT_POLICY_MAX_LAYERS)
        why = "the file has " + global.botPolicyNetLine[12] + " layers";

prevOut = BOT_OBS_LENGTH;
if (why == "")
{
    for (L = 0; L < layers; L += 1)
    {
        nin = real(file_text_read_string(f));
        file_text_readln(f);
        nout = real(file_text_read_string(f));
        file_text_readln(f);
        w = ds_grid_create(1, 1);
        ds_list_add(grids, w);
        ds_grid_read(w, file_text_read_string(f));
        file_text_readln(f);
        b = ds_grid_create(1, 1);
        ds_list_add(grids, b);
        ds_grid_read(b, file_text_read_string(f));
        file_text_readln(f);
        if (nin != prevOut)
        {
            why = "layer " + string(L) + " takes " + string(nin) + " inputs where the previous layer gives " + string(prevOut);
            break;
        }
        // ds_grid_read returns nothing; check dimensions
        if ((L mod 2) == 0)
        {
            if (ds_grid_width(w) != nout or ds_grid_height(w) != nin or ds_grid_width(b) != nout or ds_grid_height(b) != 1)
                why = "layer " + string(L) + " grids are not " + string(nout) + "x" + string(nin);
        }
        else
        {
            if (ds_grid_width(w) != nin or ds_grid_height(w) != nout or ds_grid_width(b) != 1 or ds_grid_height(b) != nout)
                why = "layer " + string(L) + " grids are not " + string(nin) + "x" + string(nout);
        }
        if (why != "")
            break;
        t = ds_grid_create(ds_grid_width(w), ds_grid_height(w));
        ds_list_add(grids, t);
        global.botPolicyNetW[n, L] = w;
        global.botPolicyNetB[n, L] = b;
        global.botPolicyNetT[n, L] = t;
        global.botPolicyNetIn[n, L] = nin;
        global.botPolicyNetOut[n, L] = nout;
        prevOut = nout;
    }
}
if (why == "")
    if (prevOut != BOT_POLICY_OUTPUTS)
        why = "the output layer is " + string(prevOut) + " wide and the heads want " + string(BOT_POLICY_OUTPUTS);

test = ds_grid_create(1, 1);
ds_list_add(grids, test);
logits = ds_grid_create(1, 1);
ds_list_add(grids, logits);
heads = "";
if (why == "")
{
    ds_grid_read(test, file_text_read_string(f));
    file_text_readln(f);
    ds_grid_read(logits, file_text_read_string(f));
    file_text_readln(f);
    heads = file_text_read_string(f);
    if (ds_grid_height(test) != BOT_OBS_LENGTH or ds_grid_width(logits) != BOT_POLICY_OUTPUTS)
        why = "the test vector is missing";
}
file_text_close(f);

if (why == "")
{
    global.botPolicyNetLabel[n] = argument1;
    global.botPolicyNetUuid[n] = global.botPolicyNetLine[4];
    global.botPolicyNetRepeat[n] = real(global.botPolicyNetLine[9]);
    global.botPolicyNetLayers[n] = layers;
    for (c = 0; c <= CLASS_QUOTE; c += 1)
    {
        global.botPolicyNetTrained[n, c] = 0;
        global.botPolicyNetDrives[n, c] = 0;
    }
    // e.g. "0,1,3,6": PlayerClass ordinals = GM8 class numbers
    list = global.botPolicyNetLine[10] + ",";
    while (list != "")
    {
        p = string_pos(",", list);
        s = string_copy(list, 1, p - 1);
        list = string_delete(list, 1, p);
        if (s == "")
            continue;
        c = real(s);
        if (c >= 0 and c <= CLASS_QUOTE)
            global.botPolicyNetTrained[n, c] = 1;
    }

    // self-test
    ds_grid_set_grid_region(global.botObsGrid, test, 0, 0, 0, BOT_OBS_LENGTH - 1, 0, 0);
    botPolicyNetAct(n);
    last = global.botPolicyNetT[n, layers - 1];
    err = 0;
    for (i = 0; i < BOT_POLICY_OUTPUTS; i += 1)
    {
        e = ds_grid_get(logits, i, 0);
        if (((layers - 1) mod 2) == 0)
            v = ds_grid_get(last, i, 0);
        else
            v = ds_grid_get(last, 0, i);
        err = max(err, abs(v - e) / max(1, abs(e)));
    }
    s = "";
    for (i = 0; i < BOT_POLICY_HEADS; i += 1)
    {
        if (i > 0)
            s += ",";
        s += string(global.botPolicyNetHead[i]);
    }
    if (err > 0.000001)
        why = "the forward pass disagrees with the converter's test vector by " + string(err) + " (ds_grid semantics?)";
    else if (s != heads)
        why = "the argmax per head is " + s + " where the converter's is " + heads + " (ds_grid_get_max/ds_grid_value_x?)";
}

if (why != "")
{
    for (i = 0; i < ds_list_size(grids); i += 1)
        ds_grid_destroy(ds_list_find_value(grids, i));
    ds_list_destroy(grids);
    global.botPolicyNetReport += "policy " + argument1 + ": REFUSED: " + why + chr(13) + chr(10);
    return -1;
}

ds_grid_destroy(test);
ds_grid_destroy(logits);
ds_list_destroy(grids);

// cost = timed forward pass + assumed observation cost
count = 0;
t0 = current_time;
do
{
    botPolicyNetAct(n);
    count += 1;
    elapsed = current_time - t0;
}
until (elapsed >= BOT_POLICY_TIMING_MS or count >= 1000);
global.botPolicyNetCost[n] = max(BOT_POLICY_COST_MIN_US, elapsed * 1000 / count + BOT_POLICY_OBS_COST_US);
ds_grid_clear(global.botObsGrid, 0);

global.botPolicyNetCount = n + 1;
global.botPolicyNetReport += "policy " + argument1 + ": trained against " + global.botPolicyNetUuid[n]
    + ", classes " + global.botPolicyNetLine[11] + ", action repeat " + global.botPolicyNetLine[9]
    + ", self-test " + heads + " ok (error " + string(err) + "), forward pass "
    + string(round(elapsed * 1000 / count)) + " us over " + string(count) + " runs" + chr(13) + chr(10);
return n;
