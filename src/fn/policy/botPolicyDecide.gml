// botPolicyDecide(player, char, tier): PolicyController.Decide - observe, run
// the net, store the six heads in player.botPolicyAction*.
// Updates the EMA cost global.botPolicyNetCost[tier] (us) from wall time;
// current_time is coarse but unbiased on average.
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
