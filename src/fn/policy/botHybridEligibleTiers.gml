// botHybridEligibleTiers(class): HybridBot.EligibleTiers - which tiers will
// drive this class, as a bitmask (bit t for tier t), asked every tick because
// a class can change mid-match. 0 when no tier drives it, or none is loaded.
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
