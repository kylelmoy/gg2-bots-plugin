// botPolicyDecide(player, char, tier): PolicyController.Decide - observe, run
// the network, hold the six heads as the bot's action
// (player.botPolicyActionHorizontal, ...Jump, ...Down, ...Fire, ...AimDelta,
// ...Zoom).
//
// Also prices the decision for the budget: the wall time of this call
// (current_time is 1-16 ms coarse, so one sample is usually 0 or a whole
// tick of the clock, but its expectation is the true cost) moves the tier's
// running estimate global.botPolicyNetCost[tier] by BOT_POLICY_COST_EMA.
var pl, ch, tier, t0, spent;
pl = argument0;
ch = argument1;
tier = argument2;
t0 = current_time;
botObsWrite(pl, ch);
botPolicyNetAct(tier);
pl.botPolicyActionHorizontal = global.botPolicyNetHead[0];
pl.botPolicyActionJump = global.botPolicyNetHead[1];
pl.botPolicyActionDown = global.botPolicyNetHead[2];
pl.botPolicyActionFire = global.botPolicyNetHead[3];
pl.botPolicyActionAimDelta = global.botPolicyNetHead[4];
pl.botPolicyActionZoom = global.botPolicyNetHead[5];
spent = (current_time - t0) * 1000;
global.botPolicyNetCost[tier] = max(BOT_POLICY_COST_MIN_US, global.botPolicyNetCost[tier] + BOT_POLICY_COST_EMA * (spent - global.botPolicyNetCost[tier]));
