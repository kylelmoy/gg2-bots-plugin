// botCombatStillWorthShootingAt(player, char): BotCombat.StillWorthShootingAt -
// target still alive, enemy and visible (botVisibilityCanSee inlined)?
// global.botRet true/false; global.botRetX/Y the aim point: character origin or
// building box centre.
var p, me, myTeam, kind, s, c, ok;
p = argument0;
me = argument1;
myTeam = p.team;
kind = p.botCombatTargetKind;
s = p.botCombatTargetSlot;
global.botRet = false;
global.botRetX = 0;
global.botRetY = 0;
if (s == noone or s == -1)
    exit;
if (!instance_exists(s))
    exit;

if (kind == BOT_TARGET_KIND_CHARACTER)
{
    c = s.object;
    if (c == -1)
        exit;
    if (c.hp <= 0)
        exit;
    if (c.cloak)
    {
        ok = false;
        if (c.stabbing)
            ok = (sign(c.x - me.x) != -sign(me.image_xscale));
        if (!ok)
            exit;
    }
    if (s.team == myTeam)
        exit;
    global.botRetX = c.x;
    global.botRetY = c.y;
    global.botRet = true;
    exit;
}

if (kind == BOT_TARGET_KIND_SENTRY or kind == BOT_TARGET_KIND_GENERATOR)
{
    if (s.hp <= 0 or s.team == myTeam)
        exit;
    global.botRetX = (s.bbox_left + s.bbox_right) / 2;
    global.botRetY = (s.bbox_top + s.bbox_bottom) / 2;
    global.botRet = true;
}
