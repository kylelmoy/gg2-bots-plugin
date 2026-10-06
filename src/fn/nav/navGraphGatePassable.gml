// navGraphGatePassable(gate, team, hasIntel, setupGatesClosed):
// NavGraph.GatePassable (navGatePassable.gml) - whether this traveller may pass
// a gate code (NAV_GATE_*).
//
// Mirrors charSetSolids, the only place the engine decides it:
//   TeamGate   solid = (team != other.team or other.intel)
//   IntelGate  solid = (team != other.team and other.intel)
// So your own team gate is open unless you carry intel out of it, and an enemy
// intel gate is closed only to a carrier. An unknown code refuses passage.
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
