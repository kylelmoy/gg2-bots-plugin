// navGenStep(budgetMs): run generation units until budgetMs of current_time
// has passed (at least one unit), or the graph or the tables are finished.
// global.navGenMs accumulates the time spent; global.navGenStageAt[s] is the
// current_time stage s began (for timing a run that is stepped back to back);
// global.navGenLongestMs the longest single call, i.e. the worst a tick paid.
var t0, s;
if (!global.navGenActive)
    exit;
t0 = current_time;
while (true)
{
    s = global.navGenStage;
    if (s == NAV_GEN_STAGE_GRAPH_DONE || s == NAV_GEN_STAGE_DONE)
        break;
    navGenUnit();
    if (global.navGenStage != s)
        global.navGenStageAt[global.navGenStage] = current_time;
    if (current_time - t0 >= argument0)
        break;
}
global.navGenMs += current_time - t0;
global.navGenLongestMs = max(global.navGenLongestMs, current_time - t0);
