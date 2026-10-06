// botAllyStillValid(player, ally): BotAlly.StillValid - is this (a Player
// instance, or noone) still a team-mate worth beaming. Re-asked every tick: an
// ally can die, change team, leave, or cloak between refreshes.
var p, a, c;
p = argument0;
a = argument1;
if (a == noone or a == -1)
    return false;
if (!instance_exists(a))
    return false;
if (a.object == -1 or p.object == -1)
    return false;
c = a.object;
if (c.hp <= 0)
    return false;
if (c.cloak)
    return false;
return (a.team == p.team);
