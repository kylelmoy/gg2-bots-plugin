// botAllyStillValid(player, ally): BotAlly.StillValid - is ally (a Player or
// noone) still a live, uncloaked team-mate.
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
