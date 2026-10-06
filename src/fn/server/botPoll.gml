// botPoll(player): one bot's decision for the next tick, written onto its
// character exactly as processClientCommands writes a client's INPUTSTATE.
var char, keys, dir, dist, net;
char = argument0.object;
if (char == -1)
{
    botThink(argument0, -1);
    exit;
}
botThink(argument0, char);
keys = global.botRet;
dir = global.botRetAim;
dist = global.botRetAimDist;
net = floor(dir * 65536 / 360 + 0.5) mod 65536;
if (net < 0)
    net += 65536;
with (char)
{
    keyState = keys;
    netAimDirection = net;
    aimDirection = netAimDirection * 360 / 65536;
    aimDistance = min(255, max(0, floor(dist / 2))) * 2;
    event_user(1);
}
