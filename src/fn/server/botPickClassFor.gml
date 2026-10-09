// botPickClassFor(player, team): BotPopulation.PickClass - a random class with
// room under both [BotClasslimits] and the server's class limits, or -1. player
// (or noone) is excluded from counts.
var c, n, possible, picked, guard;
possible = false;
for (c = 0; c <= CLASS_PYRO; c += 1)
{
    n = 0;
    with (Player)
        if (botIsBot and id != argument0 and team == argument1 and class == c)
            n += 1;
    global.botTmpRoom[c] = (n < global.botClassLimit[c]) and (countClassmembersExcept(argument0, argument1, c) < global.classlimits[c]);
    if (global.botTmpRoom[c])
        possible = true;
}
if (!possible)
    return -1;
guard = 0;
while (guard < 1000)
{
    picked = irandom(8);
    if (global.botTmpRoom[picked])
        return picked;
    guard += 1;
}
return -1;
