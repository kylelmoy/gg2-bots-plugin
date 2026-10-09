// botPopulationService(): BotPopulationService.Service, once a tick - reteam,
// reclass, then add or remove bots towards the target.
var humans, bots, joining, target, reserve, red, blue, team, cls, toRemove, pick;

humans = 0;
bots = 0;
with (Player)
{
    if (botIsBot)
    {
        if (!variable_local_exists("botLeaving"))
            bots += 1;
    }
    else if (!(global.dedicatedMode and id == global.myself))
        humans += 1;
}
joining = ds_list_size(global.botJoining);

botPopulationReteam();
botPopulationReclass();

if (!global.botEnabled or humans < global.botMinHumans)
    target = 0;
else
    target = min(global.botMaxBots, max(0, global.botFillToPlayers - humans));

// Keep one slot free for the next person (RESERVE_SLOT refuses at PlayerLimit).
// Not in the C#.
reserve = getNumberOfOccupiedSlots();
with (JoiningPlayer)
    if (!occupiesSlot)
        reserve += 1;
target = min(target, bots + joining + (global.playerLimit - 1 - reserve));
target = max(0, target);

if (bots + joining < target)
{
    repeat (target - bots - joining)
    {
        botCountTeams();
        red = global.botRet;
        blue = global.botRetBlue;
        team = botPickTeam(red, blue);
        cls = botPickClassFor(noone, team);
        if (cls < 0)
            break;
        botJoinStart(team, cls, global.botNamePrefix + global.botClassName[cls]);
    }
}
else if (bots > target)
{
    // A dead bot first, else the newest.
    repeat (bots - target)
    {
        pick = noone;
        with (Player)
            if (botIsBot and !variable_local_exists("botLeaving") and object == -1)
                pick = id;
        if (pick == noone)
            with (Player)
                if (botIsBot and !variable_local_exists("botLeaving"))
                    pick = id;
        if (pick == noone)
            break;
        botRemove(pick);
    }
}
