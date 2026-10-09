// botHybridEligibleTiers(class): HybridBot.EligibleTiers - bitmask (bit t =
// tier t) of tiers that drive this class; 0 for none.
var cls, bits, bit, t;
cls = argument0;
bits = 0;
bit = 1;
if (cls < 0 or cls > CLASS_QUOTE)
    return 0;
for (t = 0; t < global.botPolicyNetCount; t += 1)
{
    if (global.botPolicyNetDrives[t, cls])
        bits |= bit;
    bit *= 2;
}
return bits;
