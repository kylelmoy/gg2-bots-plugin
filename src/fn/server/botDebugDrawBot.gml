// botDebugDrawBot(player, char): one bot's part of the debug overlay
// (botDebugDraw). World coordinates; the caller's view is already applied.
// Its label (position, node, route trouble, who drives) is queued, not drawn.
var p, c, cx, cy, col, k, n, bx, by, node, label, driver, cone, len, err, skilled, driven;
p = argument0;
c = argument1;
cx = c.x;
cy = c.y;
// The knobs exist once the brain has given the bot a skill.
skilled = false;
with (p)
    skilled = variable_local_exists("botSkillSkill");
if (p.team == TEAM_RED)
    col = make_color_rgb(255, 110, 110);
else
    col = make_color_rgb(110, 160, 255);

// Route: from the bot to the node it is heading for (PathAt is the one it is
// on), and the goal, each within BOT_DEBUG_PATH_RANGE. The rest of the route
// is botDebugDrawPaths', shared with the other bots on it.
if (global.botNavReady && global.botDebugPaths)
{
    draw_set_color(col);
    draw_set_alpha(0.8);
    k = max(0, p.botPathPathAt + 1);
    if (k < ds_list_size(p.botPathPath))
    {
        n = ds_list_find_value(p.botPathPath, k);
        if (n >= 0 && n < global.botNavNodeCount)
        {
            navGraphWorldSpan(n);
            bx = (global.botRetLeft + global.botRetRight) / 2;
            by = navGraphStandY(n);
            if (point_distance(cx, cy, bx, by) <= BOT_DEBUG_PATH_RANGE)
            {
                draw_line(cx, cy, bx, by);
                draw_circle(bx, by, 2, false);
            }
        }
    }
    if (p.botPathHasGoal)
    {
        bx = p.botPathGoalX;
        by = p.botPathGoalY;
        if (point_distance(cx, cy, bx, by) <= BOT_DEBUG_PATH_RANGE)
        {
            draw_line_width(bx - 6, by - 6, bx + 6, by + 6, 2);
            draw_line_width(bx - 6, by + 6, bx + 6, by - 6, 2);
        }
    }
}

// Target and aim: cyan while the target is in sight, grey once lost.
if (p.botCombatTargetExists && global.botDebugTargeting)
{
    if (p.botCombatVisible)
    {
        draw_set_color(c_aqua);
        draw_set_alpha(0.9);
    }
    else
    {
        draw_set_color(c_gray);
        draw_set_alpha(0.6);
    }
    draw_line(cx, cy, p.botCombatTargetX, p.botCombatTargetY);
    draw_circle(p.botCombatTargetX, p.botCombatTargetY, 10, true);
}

// The aim-error cone around where the bot is aiming: what difficulty buys.
// Its half-angle is the scripted aim error, or the policy's when it drives.
if (skilled && global.botDebugTargeting)
{
    if (p.botHybridDriving >= 0)
        err = p.botSkillPolicyAimErrorDeg;
    else
        err = p.botSkillAimErrorDeg;
    cone = max(err, 0.5);
    len = 120;
    draw_set_color(c_yellow);
    draw_set_alpha(0.35);
    draw_triangle(cx, cy, cx + lengthdir_x(len, p.botCombatAimDir - cone), cy + lengthdir_y(len, p.botCombatAimDir - cone), cx + lengthdir_x(len, p.botCombatAimDir + cone), cy + lengthdir_y(len, p.botCombatAimDir + cone), false);
    draw_set_alpha(0.9);
    draw_line(cx, cy, cx + lengthdir_x(len, p.botCombatAimDir), cy + lengthdir_y(len, p.botCombatAimDir));
}

// Handover radius: an enemy inside it (a person, unless EngagesBots) while
// the scripted layer wants to fight lets the policy take the wheel - only for
// a class some network drives. Bright while the policy drives.
if (global.botDebugHandover)
{
    driven = false;
    for (k = 0; k < global.botPolicyNetCount; k += 1)
        if (global.botPolicyNetDrives[k, p.class])
            driven = true;
    if (driven)
    {
        draw_set_color(c_lime);
        if (p.botHybridDriving >= 0)
            draw_set_alpha(0.9);
        else
            draw_set_alpha(0.3);
        draw_circle(cx, cy, BOT_HYBRID_RANGE, true);
    }
}

// Label, queued for botDebugDrawLabels to lay out.
node = navGraphNodeFromWorld(cx, cy);
if (p.botHybridDriving >= 0)
    driver = "POLICY " + global.botPolicyNetLabel[p.botHybridDriving];
else
    driver = "scripted";
label = string(round(cx)) + "," + string(round(cy)) + "  node " + string(node);
if (!p.botPathHasGoal)
    label += "  (no goal)";
else if (ds_list_size(p.botPathPath) == 0)
    label += "  (no route)";
if (p.botPathStuckTicks > 0)
    label += "  stuck " + string(p.botPathStuckTicks);
label += "#" + driver;
k = global.botDebugLabelCount;
global.botDebugLabelText[k] = label;
global.botDebugLabelX[k] = cx;
global.botDebugLabelY[k] = cy;
global.botDebugLabelColor[k] = col;
global.botDebugLabelCount = k + 1;
draw_set_alpha(1);
