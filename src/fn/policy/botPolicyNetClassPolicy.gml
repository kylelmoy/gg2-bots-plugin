// botPolicyNetClassPolicy(text): BotBrain.ParseClassPolicies -
// "Class=name,..." into global.botPolicyNetAssigned[class] (lower-cased;
// "" if unnamed). Also sets global.botPolicyClassName.
// Departure: a bad or duplicate entry is skipped and reported, not fatal.
var s, p, q, entry, cname, target, c, k;

global.botPolicyClassName[CLASS_SCOUT] = "Scout";
global.botPolicyClassName[CLASS_SOLDIER] = "Soldier";
global.botPolicyClassName[CLASS_SNIPER] = "Sniper";
global.botPolicyClassName[CLASS_DEMOMAN] = "Demoman";
global.botPolicyClassName[CLASS_MEDIC] = "Medic";
global.botPolicyClassName[CLASS_ENGINEER] = "Engineer";
global.botPolicyClassName[CLASS_HEAVY] = "Heavy";
global.botPolicyClassName[CLASS_SPY] = "Spy";
global.botPolicyClassName[CLASS_PYRO] = "Pyro";
global.botPolicyClassName[CLASS_QUOTE] = "Quote";
for (c = 0; c <= CLASS_QUOTE; c += 1)
    global.botPolicyNetAssigned[c] = "";

s = string_replace_all(string_lower(argument0), " ", "") + ",";
while (s != "")
{
    p = string_pos(",", s);
    entry = string_copy(s, 1, p - 1);
    s = string_delete(s, 1, p);
    if (entry == "")
        continue;
    q = string_pos("=", entry);
    if (q <= 1 or q == string_length(entry))
    {
        global.botPolicyNetReport += "WARNING: ClassPolicy '" + entry + "': expected Class=name; ignored" + chr(13) + chr(10);
        continue;
    }
    cname = string_copy(entry, 1, q - 1);
    target = string_delete(entry, 1, q);
    // excludes Quote
    c = -1;
    for (k = 0; k < CLASS_QUOTE; k += 1)
        if (cname == string_lower(global.botPolicyClassName[k]))
            c = k;
    if (c < 0)
    {
        global.botPolicyNetReport += "WARNING: ClassPolicy '" + entry + "': '" + cname + "' is not a class a bot can be; ignored" + chr(13) + chr(10);
        continue;
    }
    if (global.botPolicyNetAssigned[c] != "")
    {
        global.botPolicyNetReport += "WARNING: ClassPolicy '" + entry + "': " + global.botPolicyClassName[c] + " is already assigned to '" + global.botPolicyNetAssigned[c] + "'; ignored" + chr(13) + chr(10);
        continue;
    }
    global.botPolicyNetAssigned[c] = target;
}
