// navGraphCanAffordRocketJump(hp): NavQuery.CanAffordRocketJump - whether a
// character of this hp may be routed over a rocket jump. Strictly greater: the
// damage lands before the bot does, so at exactly NAV_RJ_DAMAGE it dies in
// mid-air on an edge it was told to fly.
return (argument0 > NAV_RJ_DAMAGE);
