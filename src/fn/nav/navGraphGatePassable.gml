// navGraphGatePassable(gate, team, hasIntel, setupGatesClosed):
// NavGraph.GatePassable - whether this traveller may pass gate code NAV_GATE_*.
// Mirrors charSetSolids. Unknown code: false.
var gate, team, hasIntel;
gate = argument0;
team = argument1;
hasIntel = argument2;
if (gate == NAV_GATE_NONE)
    return true;
if (gate == NAV_GATE_TEAM_RED)
    return (team == TEAM_RED && !hasIntel);
if (gate == NAV_GATE_TEAM_BLUE)
    return (team == TEAM_BLUE && !hasIntel);
if (gate == NAV_GATE_INTEL_RED)
    return (team == TEAM_RED || !hasIntel);
if (gate == NAV_GATE_INTEL_BLUE)
    return (team == TEAM_BLUE || !hasIntel);
if (gate == NAV_GATE_SETUP)
    return !argument3;
return false;
