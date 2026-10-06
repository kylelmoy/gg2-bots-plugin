// botTargetingFind(player, range): BotTargeting.Find - botFindTarget.gml.
// Picks the thing this bot should shoot at, or nothing. Returns the BotTarget
// flattened:
//   global.botRet         Exists (true/false)
//   global.botRetKind     BOT_TARGET_KIND_*
//   global.botRetSlot     the target's Player instance for a character, the
//                         Sentry / Generator instance otherwise (Identity)
//   global.botRetX/Y      where to aim: a character's origin (its chest), the
//                         CENTRE of a sentry's or generator's box
//   global.botRetVisible  false for a target chosen through a wall
// Scored by threat, in pixels, lowest first:
//   character = distance - 300 carrying the intel
//               - BOT_ATTACKER_BONUS shot me personally recently (not by its sentry)
//               - 120 medic / - 60 engineer - 100 at or under 40% hp
//               + range inside my class's minimum band;     floored at 1
//   sentry    = distance - BOT_SENTRY_BONUS
//               - BOT_ATTACKER_BONUS this sentry is what is shooting me
//               + range inside my class's minimum band;     floored at 1
//   generator = BOT_GEN_THREAT + distance (only when nothing live is there)
// Line of sight is tested when a candidate is POPPED, so the collision line
// runs for the best candidates only; if every candidate is blocked, the
// nearest one inside BOT_BLIND_RANGE is returned with Visible false.
// DEPARTURE (docs/departures/combat.md): ties are broken by ds_priority, not
// by roster slot.
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
sentryObj = global.DAMAGE_SOURCE_SENTRYTURRET;

if (!variable_global_exists("botTargetingQueue"))
    global.botTargetingQueue = ds_priority_create();
q = global.botTargetingQueue;
ds_priority_clear(q);

// Characters. A cloaked spy is not a candidate at all until its knife
// animation puts it on the screen in front of this bot (botVisibilityCanSee).
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
    // A sentry's damage names its OWNER as the dealer, so the source is what
    // tells an engineer's shotgun from the gun it built; exactly one of the two
    // loops awards the bonus.
    if (player == dealer and source != sentryObj)
        threat -= BOT_ATTACKER_BONUS;
    if (player.class == CLASS_MEDIC)
        threat -= 120;
    else if (player.class == CLASS_ENGINEER)
        threat -= 60;
    if (hp <= maxHp * 0.4)
        threat -= 100;
    // The lock-breaker: anyone inside the band ranks a whole radius worse.
    if (dist < minBand)
        threat += range;
    ds_priority_add(q, id, max(1, threat));
}

// Sentries: rank a little ahead of a player at the same distance.
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

// The enemy generator, far past any distance term.
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
