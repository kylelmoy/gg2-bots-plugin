// navGenStamp(): NavInstances.StampInto - one region write per instance into
// the solid/platform/lethal/door grids, then the gates last: team gates, then
// intel gates, then setup gates, so a later stamp wins where two overlap. A
// gate's footprint is dilated up and left by the character box (navGateStamp):
// a gate cell means "a body anchored here stands in the gate".
var k, pass, stamp, code, w, h, x0, y0, x1, y1;
w = global.navGenW;
h = global.navGenH;
for (k = 0; k < global.navGenInstCount; k += 1)
{
    stamp = global.navGenInstStamp[k];
    if (stamp == NAV_GEN_STAMP_GATE || stamp == NAV_GEN_STAMP_MOVEBOX)
        continue;
    x0 = max(0, floor(global.navGenInstLeft[k] / NAV_CELL_SIZE));
    y0 = max(0, floor(global.navGenInstTop[k] / NAV_CELL_SIZE));
    x1 = min(w - 1, floor(global.navGenInstRight[k] / NAV_CELL_SIZE));
    y1 = min(h - 1, floor(global.navGenInstBottom[k] / NAV_CELL_SIZE));
    if (x0 > x1 || y0 > y1)
        continue;
    if (stamp == NAV_GEN_STAMP_SOLID)
        ds_grid_set_region(global.navGenSolid, x0, y0, x1, y1, 1);
    else if (stamp == NAV_GEN_STAMP_PLATFORM)
        ds_grid_set_region(global.navGenPlat, x0, y0, x1, y1, 1);
    else if (stamp == NAV_GEN_STAMP_LETHAL)
        ds_grid_set_region(global.navGenLethal, x0, y0, x1, y1, 1);
    else if (stamp == NAV_GEN_STAMP_DOOR_LEFT)
        ds_grid_set_region(global.navGenDoor, x0, y0, x1, y1, NAV_DOOR_LEFT);
    else if (stamp == NAV_GEN_STAMP_DOOR_RIGHT)
        ds_grid_set_region(global.navGenDoor, x0, y0, x1, y1, NAV_DOOR_RIGHT);
}

for (pass = 0; pass < 3; pass += 1)
{
    for (k = 0; k < global.navGenInstCount; k += 1)
    {
        if (global.navGenInstStamp[k] != NAV_GEN_STAMP_GATE)
            continue;
        code = global.navGenInstGate[k];
        if (pass == 0 && code != NAV_GATE_TEAM_RED && code != NAV_GATE_TEAM_BLUE)
            continue;
        if (pass == 1 && code != NAV_GATE_INTEL_RED && code != NAV_GATE_INTEL_BLUE)
            continue;
        if (pass == 2 && code != NAV_GATE_SETUP)
            continue;
        x0 = max(0, floor(global.navGenInstLeft[k] / NAV_CELL_SIZE) - (NAV_BOX_W - 1));
        y0 = max(0, floor(global.navGenInstTop[k] / NAV_CELL_SIZE) - (NAV_BOX_H - 1));
        x1 = min(w - 1, floor(global.navGenInstRight[k] / NAV_CELL_SIZE));
        y1 = min(h - 1, floor(global.navGenInstBottom[k] / NAV_CELL_SIZE));
        if (x0 > x1 || y0 > y1)
            continue;
        ds_grid_set_region(global.navGenGate, x0, y0, x1, y1, code);
    }
}
