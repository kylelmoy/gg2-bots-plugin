// botTargetingFind(player, range): BotTargeting.Find - the target to shoot.
// Returns:
//   global.botRet         exists
//   global.botRetKind     BOT_TARGET_KIND_*
//   global.botRetSlot     Player for a character, else the Sentry/Generator
//   global.botRetX/Y      character origin, or building box centre
//   global.botRetVisible  false if chosen through a wall
// Threat, lowest first, floored at 1: distance - 300 intel - BOT_ATTACKER_BONUS
// if it shot me - 120 medic / - 60 engineer - 100 at <= 40% hp + range inside
// the min band. Sentry: distance - BOT_SENTRY_BONUS, same attacker/band terms.
// Generator: BOT_GEN_THREAT + distance. Sight tested on pop; if all blocked,
// nearest within BOT_BLIND_RANGE, not visible. DEPARTURE: ties broken by
// ds_priority, not roster slot.
var p, range, me, myTeam, mx, my, mxs, minBand, q, dist, threat, dealer, source;
var cand, kind, cx, cy, blind, blindKind, blindX, blindY, blindDist, vis, sentryObj;
p = argument0;
range = argument1;
global.botRet = false;
global.botRetKind = BOT_TARGET_KIND_NONE;
global.botRetSlot = noone;
global.botRetX = 0;
global.botRetY = 0;
global.botRetVisible = false;
me = p.object;
if (me == -1)
    exit;

myTeam = p.team;
mx = me.x;
my = me.y;
mxs = me.image_xscale;
dealer = me.lastDamageDealer;
source = me.lastDamageSource;
minBand = botTargetingClassMinBand(p.class);
// That call left its result in global.botRet; nothing found is still false.
global.botRet = false;
sentryObj = global.DAMAGE_SOURCE_SENTRYTURRET;

if (!variable_global_exists("botTargetingQueue"))
    global.botTargetingQueue = ds_priority_create();
q = global.botTargetingQueue;
ds_priority_clear(q);

// Cloaked spies only while stabbing in front (botVisibilityCanSee).
with (Character)
{
    if (id == me)
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
    if (player.team == myTeam)
        continue;
    if (hp <= 0)
        continue;
    dist = point_distance(x, y, mx, my);
    if (dist > range)
        continue;
    threat = dist;
    if (intel)
        threat -= 300;
    // Sentry damage names the owner as dealer; the source decides which loop
    // gets the bonus.
    if (player == dealer and source != sentryObj)
        threat -= BOT_ATTACKER_BONUS;
    if (player.class == CLASS_MEDIC)
        threat -= 120;
    else if (player.class == CLASS_ENGINEER)
        threat -= 60;
    if (hp <= maxHp * 0.4)
        threat -= 100;
    // Inside the min band: a whole radius worse.
    if (dist < minBand)
        threat += range;
    ds_priority_add(q, id, max(1, threat));
}

with (Sentry)
{
    if (team == myTeam)
        continue;
    if (hp <= 0)
        continue;
    dist = point_distance(x, y, mx, my);
    if (dist > range)
        continue;
    threat = dist - BOT_SENTRY_BONUS;
    if (ownerPlayer == dealer and source == sentryObj)
        threat -= BOT_ATTACKER_BONUS;
    if (dist < minBand)
        threat += range;
    ds_priority_add(q, id, max(1, threat));
}

with (Generator)
{
    if (team == myTeam)
        continue;
    if (hp <= 0)
        continue;
    cx = (bbox_left + bbox_right) / 2;
    cy = (bbox_top + bbox_bottom) / 2;
    dist = point_distance(cx, cy, mx, my);
    if (dist <= range)
        ds_priority_add(q, id, BOT_GEN_THREAT + dist);
}

blind = noone;
blindKind = BOT_TARGET_KIND_NONE;
blindX = 0;
blindY = 0;
blindDist = 0;
while (!ds_priority_empty(q))
{
    cand = ds_priority_delete_min(q);
    if (cand.object_index == Sentry)
        kind = BOT_TARGET_KIND_SENTRY;
    else if (object_is_ancestor(cand.object_index, Generator))
        kind = BOT_TARGET_KIND_GENERATOR;
    else
        kind = BOT_TARGET_KIND_CHARACTER;
    if (kind == BOT_TARGET_KIND_CHARACTER)
    {
        cx = cand.x;
        cy = cand.y;
    }
    else
    {
        cx = (cand.bbox_left + cand.bbox_right) / 2;
        cy = (cand.bbox_top + cand.bbox_bottom) / 2;
    }
    if (!collision_line_bulletblocking(mx, my, cx, cy))
    {
        ds_priority_clear(q);
        global.botRet = true;
        global.botRetKind = kind;
        if (kind == BOT_TARGET_KIND_CHARACTER)
            global.botRetSlot = cand.player;
        else
            global.botRetSlot = cand;
        global.botRetX = cx;
        global.botRetY = cy;
        global.botRetVisible = true;
        exit;
    }
    dist = point_distance(cx, cy, mx, my);
    if (dist > BOT_BLIND_RANGE)
        continue;
    if (blind == noone or dist < blindDist)
    {
        blind = cand;
        blindKind = kind;
        blindX = cx;
        blindY = cy;
        blindDist = dist;
    }
}

if (blind != noone)
{
    global.botRet = true;
    global.botRetKind = blindKind;
    if (blindKind == BOT_TARGET_KIND_CHARACTER)
        global.botRetSlot = blind.player;
    else
        global.botRetSlot = blind;
    global.botRetX = blindX;
    global.botRetY = blindY;
    global.botRetVisible = false;
}
