// botStabWindow(char, targetChar): BotStab.Window - would a stab now connect:
// target's predicted bounds (constant hspeed, botAimFallPredict) at
// t+BOT_STAB_LEAD_MIN..MAX vs StabMaskS's box (BOT_STAB_REACH forward/up,
// BOT_STAB_BACK back/down). aimDirection in [90, 270] faces left. Ignores
// cloak, readyToStab, team.
var me, tg, facing, maskLeft, maskRight, maskTop, maskBottom, fl, vx, vy, t, px, py;
me = argument0;
tg = argument1;
facing = 1;
if (me.aimDirection >= 90 and me.aimDirection <= 270)
    facing = -1;
if (facing > 0)
{
    maskLeft = me.x - BOT_STAB_BACK;
    maskRight = me.x + BOT_STAB_REACH;
}
else
{
    maskLeft = me.x - BOT_STAB_REACH;
    maskRight = me.x + BOT_STAB_BACK;
}
maskTop = me.y - BOT_STAB_REACH;
maskBottom = me.y + BOT_STAB_BACK;

fl = botAimFloorUnder(tg.x, tg.y);
vx = tg.hspeed;
vy = tg.vspeed;
for (t = BOT_STAB_LEAD_MIN; t <= BOT_STAB_LEAD_MAX; t += 1)
{
    px = tg.x + vx * t;
    py = botAimFallPredict(tg.y, vy, t, fl);
    if (px + tg.right_bound_offset >= maskLeft
        and px + tg.left_bound_offset <= maskRight
        and py + tg.bottom_bound_offset >= maskTop
        and py + tg.top_bound_offset <= maskBottom)
        return true;
}
return false;
