// botObjectiveCarrier(team): BotObjective.Carrier - the Character on `team`
// carrying a briefcase, or noone.
// Departure: returns the Character, not a roster slot. First in instance order
// wins.
var chaseTeam, carrier;
chaseTeam = argument0;
carrier = noone;
with (Character)
{
    if (carrier == noone)
    {
        if (intel)
        {
            if (team == chaseTeam)
                carrier = id;
        }
    }
}
return carrier;
