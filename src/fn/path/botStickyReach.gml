// botStickyReach(char, needVx, flightTicks, v0) - StickyModel.Reach: how far
// along a sticky-jump arc the character gets. Deliberately DELEGATED to
// botRocketReach rather than copied: a mine jump flies under moveStatus 1
// exactly as a rocket jump does (control NAV_RJ_CONTROL, friction
// NAV_RJ_FRICTION), and the one thing a rocket has that a mine does not
// (NAV_RJ_SPEEDUP) is not used by that integration.
return botRocketReach(argument0, argument1, argument2, argument3);
