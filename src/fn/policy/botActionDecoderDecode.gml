// botActionDecoderDecode(player, firstTickOfDecision): ActionDecoder.Decode -
// the held action (player.botPolicyAction*) as this tick's input.
// Returns BOT_KEY_* bits; global.botRetAimNet (wire units 0..65535),
// global.botRetAim (degrees), global.botRetAimDist (100 px).
// Jump and the turn apply on a decision's first tick only.
// player.botActionDecoderAim: degrees in [0, 360). Zoom head not decoded.
var pl, first, keys, aim, t, net;
pl = argument0;
first = argument1;
keys = 0;
if (pl.botPolicyActionHorizontal == 1)
    keys |= BOT_KEY_LEFT;
else if (pl.botPolicyActionHorizontal == 2)
    keys |= BOT_KEY_RIGHT;
if (pl.botPolicyActionDown != 0)
    keys |= BOT_KEY_DOWN;
if (pl.botPolicyActionJump != 0)
    if (first)
        keys |= BOT_KEY_JUMP;
if (pl.botPolicyActionFire == 1)
    keys |= BOT_KEY_ATTACK;
else if (pl.botPolicyActionFire == 2)
    keys |= BOT_KEY_SPECIAL;

if (first)
{
    t = botActionDecoderTurnFor(pl.botPolicyActionAimDelta);
    aim = pl.botActionDecoderAim + t;
    aim -= floor(aim / 360) * 360;
    pl.botActionDecoderAim = aim;
}

net = floor(pl.botActionDecoderAim * 65536 / 360 + 0.5);
if (net > 65535)
    net = 65535;
if (net < 0)
    net = 0;
global.botRetAimNet = net;
global.botRetAim = net * 360 / 65536;
global.botRetAimDist = BOT_ACTION_AIM_DISTANCE;
return keys;
