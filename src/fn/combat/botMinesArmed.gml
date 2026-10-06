// botMinesArmed(player): BotMines.Armed - botMinesArmed.gml. Has any mine this
// bot has out (Mine.ownerPlayer == player) got an enemy inside the radius that
// actually hurts - the moment SPECIAL is worth pressing, since the Minegun
// detonates every mine at once.
//   a character  centre to centre <= BOT_MINE_TRIGGER, and only one this
//                demoman can see (botVisibilityCanSee, inlined)
//   a sentry     distance_to_object (box to box) < BOT_MINE_TRIGGER
//   a generator  the same, either generator, the team test picks the enemy's
// Teams are the CHARACTER's (the mines belong to the body that lobbed them).
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
