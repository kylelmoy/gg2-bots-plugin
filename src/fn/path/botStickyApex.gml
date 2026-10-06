// botStickyApex() - StickyModel.Apex: the apex a sticky launch reaches with
// nothing in the way, v^2 / 2g, under moveStatus 1's gravity
// (ClassStats.RocketJumpGravity). 193.6 px. StickyModel.Launch is the constant
// BOT_STICKY_LAUNCH (-14.46 px/tick, measured, not derived).
return BOT_STICKY_LAUNCH * BOT_STICKY_LAUNCH / (2 * BOT_STICKY_APEX_GRAVITY);
