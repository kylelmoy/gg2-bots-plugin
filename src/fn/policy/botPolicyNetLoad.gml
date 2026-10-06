// botPolicyNetLoad(): load every policy checkpoint at server start.
//
// gg2-server's BotBrain.Build for BotMode.Policy, reduced to what a GML
// server has: every build/data/policy file shipped in global.botDir +
// "policy\" (made by tools/convert-policy.js from the .npz checkpoints) is
// one tier, in file-name order, and drives the classes its own file claims
// (PolicyNetwork.TrainedClasses), adjusted by [Bots] ClassPolicy exactly as
// BotBrain.Build resolves it: an explicit Class=name wins, Class=scripted
// takes the class away from every tier, and the file's set fills in every
// class nobody named.
//
// [Bots] Mode (global.botMode, read by botConfigLoad) "scripted" disables the
// policy entirely: nothing is loaded and every class stays scripted.
//
// [Bots] Arbiter is the per-tick decision budget in microseconds, as on
// gg2-server; unset, BOT_ARBITER_DEFAULT_US (docs/departures/policy.md).
//
// Where gg2-server refuses to START over a bad checkpoint or a bad
// ClassPolicy entry, this refuses the checkpoint or the entry and writes why
// to global.botDir + "policy.log" (also kept in global.botPolicyNetReport): a
// modal dialog on a dedicated server is worse than a scripted bot.
//
// Returns how many checkpoints loaded.
var names, name, i, n, c, k, text, classPolicy, arbiter, f, known, owner;

// A server started twice in one game must not leak the first one's grids.
botPolicyNetFree();
global.botPolicyNetCount = 0;
global.botPolicyNetReport = "";
global.botArbiterTick = -1;
global.botArbiterSpent = 0;

// ActionDecoder.HeadShape, as offsets into the 27 logits.
global.botPolicyHeadWidth[0] = 3;
global.botPolicyHeadWidth[1] = 2;
global.botPolicyHeadWidth[2] = 2;
global.botPolicyHeadWidth[3] = 3;
global.botPolicyHeadWidth[4] = BOT_ACTION_AIM_BINS;
global.botPolicyHeadWidth[5] = 2;
k = 0;
for (i = 0; i < BOT_POLICY_HEADS; i += 1)
{
    global.botPolicyHeadAt[i] = k;
    k += global.botPolicyHeadWidth[i];
    global.botPolicyNetHead[i] = 0;
}

botObsInit();

ini_open("gg2.ini");
arbiter = ini_read_string("Bots", "Arbiter", "");
classPolicy = ini_read_string("Bots", "ClassPolicy", "");
ini_close();
if (arbiter == "")
    global.botArbiterBudget = BOT_ARBITER_DEFAULT_US;
else
    global.botArbiterBudget = max(0, real(arbiter));

if (global.botMode == "scripted")
{
    global.botPolicyNetReport = "policy: [Bots] Mode is scripted; no checkpoint loaded, every class is scripted" + chr(13) + chr(10);
}
else
{
    names = ds_list_create();
    name = file_find_first(global.botDir + "policy\*.txt", 0);
    while (name != "")
    {
        ds_list_add(names, name);
        name = file_find_next();
    }
    file_find_close();
    // File-name order, so the tier order is the same on every machine. The
    // shipped tiers drive disjoint classes, so order changes nothing there.
    ds_list_sort(names, true);

    for (i = 0; i < ds_list_size(names); i += 1)
    {
        if (global.botPolicyNetCount >= BOT_POLICY_MAX_NETS)
            break;
        name = ds_list_find_value(names, i);
        n = botPolicyNetLoadFile(global.botDir + "policy\" + name, string_copy(name, 1, string_length(name) - 4));
    }
    ds_list_destroy(names);

    if (global.botPolicyNetCount == 0)
        global.botPolicyNetReport += "policy: no checkpoint loaded from " + global.botDir + "policy\; every class is scripted" + chr(13) + chr(10);

    botPolicyNetClassPolicy(classPolicy);

    // BotBrain.Build's resolution, per tier and class.
    for (n = 0; n < global.botPolicyNetCount; n += 1)
    {
        text = "";
        for (c = 0; c <= CLASS_QUOTE; c += 1)
        {
            if (global.botPolicyNetAssigned[c] == "")
                global.botPolicyNetDrives[n, c] = global.botPolicyNetTrained[n, c];
            else
                global.botPolicyNetDrives[n, c] = (global.botPolicyNetAssigned[c] == string_lower(global.botPolicyNetLabel[n]));
            if (global.botPolicyNetDrives[n, c])
            {
                if (text != "")
                    text += ",";
                text += global.botPolicyClassName[c];
                if (global.botPolicyNetDrives[n, c] and !global.botPolicyNetTrained[n, c])
                    global.botPolicyNetReport += "WARNING: " + global.botPolicyNetLabel[n] + " is configured to drive " + global.botPolicyClassName[c] + ", which its own class set does not list" + chr(13) + chr(10);
            }
        }
        if (text == "")
        {
            text = "nothing";
            global.botPolicyNetReport += "WARNING: " + global.botPolicyNetLabel[n] + " drives no classes at all, so it is loaded and never consulted" + chr(13) + chr(10);
        }
        global.botPolicyNetReport += "policy " + global.botPolicyNetLabel[n] + ": drives " + text + chr(13) + chr(10);
    }

    // A ClassPolicy target no loaded checkpoint answers to: gg2-server
    // refuses to start; here the class stays scripted, said out loud.
    for (c = 0; c < CLASS_QUOTE; c += 1)
    {
        if (global.botPolicyNetAssigned[c] == "" or global.botPolicyNetAssigned[c] == "scripted")
            continue;
        known = false;
        for (n = 0; n < global.botPolicyNetCount; n += 1)
            if (global.botPolicyNetAssigned[c] == string_lower(global.botPolicyNetLabel[n]))
                known = true;
        if (!known)
            global.botPolicyNetReport += "WARNING: ClassPolicy " + global.botPolicyClassName[c] + "=" + global.botPolicyNetAssigned[c] + ": no checkpoint is loaded under that name; " + global.botPolicyClassName[c] + " stays scripted" + chr(13) + chr(10);
    }

    // Two tiers on one class: the earlier takes it whenever the budget allows.
    for (c = 0; c < CLASS_QUOTE; c += 1)
    {
        owner = -1;
        for (n = 0; n < global.botPolicyNetCount; n += 1)
        {
            if (!global.botPolicyNetDrives[n, c])
                continue;
            if (owner >= 0)
                global.botPolicyNetReport += "WARNING: " + global.botPolicyClassName[c] + " is driven by both " + global.botPolicyNetLabel[owner] + " and " + global.botPolicyNetLabel[n] + "; " + global.botPolicyNetLabel[owner] + " takes it whenever the budget admits it" + chr(13) + chr(10);
            else
                owner = n;
        }
    }
}

global.botPolicyNetReport += "policy: decision budget " + string(global.botArbiterBudget) + " us a tick" + chr(13) + chr(10);

f = file_text_open_write(global.botDir + "policy.log");
file_text_write_string(f, global.botPolicyNetReport);
file_text_close(f);

return global.botPolicyNetCount;
