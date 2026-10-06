// botPopulationService(): gg2-server's BotPopulationService.Service, once a tick.
//
// Put every bot on a team (a map change drops the whole roster to spectator,
// and a bot has no menu to answer), re-roll the class of a bot that died or is
// over its limit, then add or remove bots towards the target.
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

// A bot holds a real slot, so leave one free for the next person to arrive:
// RESERVE_SLOT refuses a joiner when the roster is at PlayerLimit, and a bot
// leaving afterwards does not help them. gg2-server has no such limit to keep.
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
    // A dead bot first, so nobody watches a character vanish; else the newest.
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
