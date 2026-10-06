// botActionDecoderDecode(player, firstTickOfDecision): ActionDecoder.Decode -
// the held action (player.botPolicyAction*) as this tick's input.
//
// Returns the keys (global.botRet, BOT_KEY_* bits), the aim in wire units in
// global.botRetAimNet (0..65535, PlayerInput.FromAim: round half away from
// zero, clipped), the same aim in degrees in global.botRetAim, and the aim
// distance, a fixed 100 px, in global.botRetAimDist.
//
// The mask is built fresh every tick, never OR-ed into the last one. Jump is
// an EDGE in GG2, so its bit is sent on the first tick of a decision only, and
// the turn is applied once per decision, not per tick - repeating it would
// multiply the turn-rate cap by the action repeat. The decoder's absolute aim
// is per bot: player.botActionDecoderAim, degrees in [0, 360).
// The zoom head is not decoded: it is not a key, HybridBot issues no command
// for it, and only a sniper (never policy-driven here) could use it.
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
