// botObjectiveCarrier(team): BotObjective.Carrier - the Character on `team`
// carrying a briefcase, or noone. One flag each, so team alone identifies it.
//
// The C# returns a roster slot; this returns the Character instance, since the
// caller only wants its position. Team is Character.team, which the Create event
// copies from player.team and which cannot go stale (a team change kills the
// character), so it is the C#'s Player(slot).Team without a dereference through
// `player`. Several carriers cannot happen; if they did, the
// first in instance order wins, as the lowest slot does in the C#.
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
