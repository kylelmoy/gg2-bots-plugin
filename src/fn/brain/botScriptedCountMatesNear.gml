// botScriptedCountMatesNear(player, char): ScriptedBot.CountMatesNear - living
// team-mates within BOT_REGROUP_RADIUS.
var p, char, mates;
p = argument0;
char = argument1;
mates = 0;
with (Player)
{
    if (id == p or object == -1 or team != p.team)
        continue;
    if (object.hp <= 0)
        continue;
    if (point_distance(object.x, object.y, char.x, char.y) <= BOT_REGROUP_RADIUS)
        mates += 1;
}
return mates;
