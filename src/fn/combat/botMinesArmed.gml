// botMinesArmed(player): BotMines.Armed - does any of this bot's mines have an
// enemy in range: a visible character (centre <= BOT_MINE_TRIGGER,
// botVisibilityCanSee inlined) or a sentry/generator (distance_to_object <
// BOT_MINE_TRIGGER). Teams are the character's.
var p, me, myTeam, mx, mxs, armed, mineId, vis;
p = argument0;
me = p.object;
if (me == -1)
    return false;
myTeam = me.team;
mx = me.x;
mxs = me.image_xscale;
armed = false;

with (Mine)
{
    if (ownerPlayer != p)
        continue;
    mineId = id;
    with (Character)
    {
        if (team == myTeam)
            continue;
        vis = true;
        if (cloak)
        {
            vis = false;
            if (stabbing)
                vis = (sign(x - mx) != -sign(mxs));
        }
        if (!vis)
            continue;
        if (hp <= 0)
            continue;
        if (point_distance(x, y, mineId.x, mineId.y) <= BOT_MINE_TRIGGER)
        {
            armed = true;
            break;
        }
    }
    if (armed)
        break;
    with (Sentry)
    {
        if (team == myTeam)
            continue;
        if (hp <= 0)
            continue;
        if (distance_to_object(mineId) < BOT_MINE_TRIGGER)
        {
            armed = true;
            break;
        }
    }
    if (armed)
        break;
    with (Generator)
    {
        if (team == myTeam)
            continue;
        if (hp <= 0)
            continue;
        if (distance_to_object(mineId) < BOT_MINE_TRIGGER)
        {
            armed = true;
            break;
        }
    }
    if (armed)
        break;
}
return armed;
