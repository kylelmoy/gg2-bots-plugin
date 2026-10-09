// navGenCollect(): NavInstances.Instantiate - every nav-relevant instance in
// the room as a box and what it stamps, in creation order (instance id), which
// is the level data's order and decides overlaps. Fills global.navGenInst*[k]
// for k < global.navGenInstCount.
//
// Each object is matched exactly (object_index), as the C# matches an entity
// type: MovingPlatform is a DropdownPlatform child and is skipped, as there.
// The box is the C#'s: the collider sprite's size times the instance's scale
// from its rounded position, not the live bbox.
var types, lst, k, t, inst, obj, sw, sh, x0, x1, y0, y1, push, n;
types = ds_map_create();
n = 0;
// object, stamp, gate code, sprite w, sprite h
global.navGenTObj[n] = PlayerWall; global.navGenTStamp[n] = NAV_GEN_STAMP_SOLID; global.navGenTGate[n] = 0; global.navGenTW[n] = NAV_GEN_BAR_SHORT; global.navGenTH[n] = NAV_GEN_BAR_LONG; n += 1;
global.navGenTObj[n] = PlayerWallHorizontal; global.navGenTStamp[n] = NAV_GEN_STAMP_SOLID; global.navGenTGate[n] = 0; global.navGenTW[n] = NAV_GEN_BAR_LONG; global.navGenTH[n] = NAV_GEN_BAR_SHORT; n += 1;
global.navGenTObj[n] = DropdownPlatform; global.navGenTStamp[n] = NAV_GEN_STAMP_PLATFORM; global.navGenTGate[n] = 0; global.navGenTW[n] = NAV_GEN_BAR_LONG; global.navGenTH[n] = NAV_GEN_BAR_SHORT; n += 1;
global.navGenTObj[n] = KillBox; global.navGenTStamp[n] = NAV_GEN_STAMP_LETHAL; global.navGenTGate[n] = 0; global.navGenTW[n] = NAV_GEN_BOX; global.navGenTH[n] = NAV_GEN_BOX; n += 1;
global.navGenTObj[n] = PitFall; global.navGenTStamp[n] = NAV_GEN_STAMP_LETHAL; global.navGenTGate[n] = 0; global.navGenTW[n] = NAV_GEN_BOX; global.navGenTH[n] = NAV_GEN_BOX; n += 1;
global.navGenTObj[n] = FragBox; global.navGenTStamp[n] = NAV_GEN_STAMP_LETHAL; global.navGenTGate[n] = 0; global.navGenTW[n] = NAV_GEN_BOX; global.navGenTH[n] = NAV_GEN_BOX; n += 1;
global.navGenTObj[n] = LeftDoor; global.navGenTStamp[n] = NAV_GEN_STAMP_DOOR_LEFT; global.navGenTGate[n] = 0; global.navGenTW[n] = NAV_GEN_BAR_SHORT; global.navGenTH[n] = NAV_GEN_BAR_LONG; n += 1;
global.navGenTObj[n] = RightDoor; global.navGenTStamp[n] = NAV_GEN_STAMP_DOOR_RIGHT; global.navGenTGate[n] = 0; global.navGenTW[n] = NAV_GEN_BAR_SHORT; global.navGenTH[n] = NAV_GEN_BAR_LONG; n += 1;
// Gates. The "2" and horizontal variants are floors (sprite44). IntelGate-
// Horizontal/Vertical are TEAM_ANY and stamp as blue: navMarkInstances' quirk,
// kept by the C#.
global.navGenTObj[n] = RedTeamGate; global.navGenTStamp[n] = NAV_GEN_STAMP_GATE; global.navGenTGate[n] = NAV_GATE_TEAM_RED; global.navGenTW[n] = NAV_GEN_BAR_SHORT; global.navGenTH[n] = NAV_GEN_BAR_LONG; n += 1;
global.navGenTObj[n] = BlueTeamGate; global.navGenTStamp[n] = NAV_GEN_STAMP_GATE; global.navGenTGate[n] = NAV_GATE_TEAM_BLUE; global.navGenTW[n] = NAV_GEN_BAR_SHORT; global.navGenTH[n] = NAV_GEN_BAR_LONG; n += 1;
global.navGenTObj[n] = RedTeamGate2; global.navGenTStamp[n] = NAV_GEN_STAMP_GATE; global.navGenTGate[n] = NAV_GATE_TEAM_RED; global.navGenTW[n] = NAV_GEN_BAR_LONG; global.navGenTH[n] = NAV_GEN_BAR_SHORT; n += 1;
global.navGenTObj[n] = BlueTeamGate2; global.navGenTStamp[n] = NAV_GEN_STAMP_GATE; global.navGenTGate[n] = NAV_GATE_TEAM_BLUE; global.navGenTW[n] = NAV_GEN_BAR_LONG; global.navGenTH[n] = NAV_GEN_BAR_SHORT; n += 1;
global.navGenTObj[n] = RedIntelGate; global.navGenTStamp[n] = NAV_GEN_STAMP_GATE; global.navGenTGate[n] = NAV_GATE_INTEL_RED; global.navGenTW[n] = NAV_GEN_BAR_SHORT; global.navGenTH[n] = NAV_GEN_BAR_LONG; n += 1;
global.navGenTObj[n] = BlueIntelGate; global.navGenTStamp[n] = NAV_GEN_STAMP_GATE; global.navGenTGate[n] = NAV_GATE_INTEL_BLUE; global.navGenTW[n] = NAV_GEN_BAR_SHORT; global.navGenTH[n] = NAV_GEN_BAR_LONG; n += 1;
global.navGenTObj[n] = RedIntelGate2; global.navGenTStamp[n] = NAV_GEN_STAMP_GATE; global.navGenTGate[n] = NAV_GATE_INTEL_RED; global.navGenTW[n] = NAV_GEN_BAR_LONG; global.navGenTH[n] = NAV_GEN_BAR_SHORT; n += 1;
global.navGenTObj[n] = BlueIntelGate2; global.navGenTStamp[n] = NAV_GEN_STAMP_GATE; global.navGenTGate[n] = NAV_GATE_INTEL_BLUE; global.navGenTW[n] = NAV_GEN_BAR_LONG; global.navGenTH[n] = NAV_GEN_BAR_SHORT; n += 1;
global.navGenTObj[n] = IntelGateHorizontal; global.navGenTStamp[n] = NAV_GEN_STAMP_GATE; global.navGenTGate[n] = NAV_GATE_INTEL_BLUE; global.navGenTW[n] = NAV_GEN_BAR_LONG; global.navGenTH[n] = NAV_GEN_BAR_SHORT; n += 1;
global.navGenTObj[n] = IntelGateVertical; global.navGenTStamp[n] = NAV_GEN_STAMP_GATE; global.navGenTGate[n] = NAV_GATE_INTEL_BLUE; global.navGenTW[n] = NAV_GEN_BAR_SHORT; global.navGenTH[n] = NAV_GEN_BAR_LONG; n += 1;
global.navGenTObj[n] = ControlPointSetupGate; global.navGenTStamp[n] = NAV_GEN_STAMP_GATE; global.navGenTGate[n] = NAV_GATE_SETUP; global.navGenTW[n] = NAV_GEN_SETUP_GATE; global.navGenTH[n] = NAV_GEN_SETUP_GATE; n += 1;
global.navGenTObj[n] = MoveBoxUp; global.navGenTStamp[n] = NAV_GEN_STAMP_MOVEBOX; global.navGenTGate[n] = 0; global.navGenTW[n] = NAV_GEN_BOX; global.navGenTH[n] = NAV_GEN_BOX; n += 1;
global.navGenTObj[n] = MoveBoxDown; global.navGenTStamp[n] = NAV_GEN_STAMP_MOVEBOX; global.navGenTGate[n] = 0; global.navGenTW[n] = NAV_GEN_BOX; global.navGenTH[n] = NAV_GEN_BOX; n += 1;
global.navGenTObj[n] = MoveBoxLeft; global.navGenTStamp[n] = NAV_GEN_STAMP_MOVEBOX; global.navGenTGate[n] = 0; global.navGenTW[n] = NAV_GEN_BOX; global.navGenTH[n] = NAV_GEN_BOX; n += 1;
global.navGenTObj[n] = MoveBoxRight; global.navGenTStamp[n] = NAV_GEN_STAMP_MOVEBOX; global.navGenTGate[n] = 0; global.navGenTW[n] = NAV_GEN_BOX; global.navGenTH[n] = NAV_GEN_BOX; n += 1;

lst = ds_list_create();
for (t = 0; t < n; t += 1)
{
    obj = global.navGenTObj[t];
    ds_map_add(types, obj, t);
    with (obj)
        if (object_index == obj)
            ds_list_add(lst, id);
}
ds_list_sort(lst, true);

global.navGenInstCount = 0;
for (k = 0; k < ds_list_size(lst); k += 1)
{
    inst = ds_list_find_value(lst, k);
    t = ds_map_find_value(types, inst.object_index);
    sw = global.navGenTW[t];
    sh = global.navGenTH[t];
    x0 = round(inst.x);
    x1 = round(inst.x + sw * inst.image_xscale);
    y0 = round(inst.y);
    y1 = round(inst.y + sh * inst.image_yscale);
    n = global.navGenInstCount;
    global.navGenInstStamp[n] = global.navGenTStamp[t];
    global.navGenInstGate[n] = global.navGenTGate[t];
    global.navGenInstLeft[n] = min(x0, x1);
    global.navGenInstRight[n] = max(x0, x1) - 1;
    global.navGenInstTop[n] = min(y0, y1);
    global.navGenInstBottom[n] = max(y0, y1) - 1;
    global.navGenInstPushX[n] = 0;
    global.navGenInstPushY[n] = 0;
    if (global.navGenTStamp[t] == NAV_GEN_STAMP_MOVEBOX)
    {
        push = NAV_GEN_DEFAULT_PUSH;
        with (inst)
            if (variable_local_exists("pushPower"))
                push = pushPower;
        if (inst.object_index == MoveBoxUp)
            global.navGenInstPushY[n] = -push;
        else if (inst.object_index == MoveBoxDown)
            global.navGenInstPushY[n] = push;
        else if (inst.object_index == MoveBoxLeft)
            global.navGenInstPushX[n] = -push;
        else
            global.navGenInstPushX[n] = push;
    }
    global.navGenInstCount = n + 1;
}
ds_list_destroy(lst);
ds_map_destroy(types);
