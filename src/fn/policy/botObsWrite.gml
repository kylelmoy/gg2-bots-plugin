// botObsWrite(player, char): ObservationWriter.Write - this bot's view of the
// world, layout v2, into global.botObsGrid (row i = column i of the C#'s
// 211-float vector). The goal is always the default AgentGoal ("engage the
// nearest enemy"): HybridBot never sets one.
//
// The grid is cleared first, so every block below writes only its non-zero
// floats: stale features are worse than absent ones (the C#'s remark), and a
// ds_grid_set skipped is interpreted work saved.
//
// Every game variable read here is listed in docs/POLICY.md, "What the
// observation reads", with where the game sets it; docs/departures/policy.md
// has the places the GML's reading can differ from gg2-server's simulation.
var pl, ch, cls;
pl = argument0;
ch = argument1;
ds_grid_clear(global.botObsGrid, 0);
global.botObsEnemy0 = noone;
global.botObsEnemy0D = -1;

// A dead player observes nothing (the C# returns the cleared span).
if (ch < 0)
    exit;
cls = pl.class;
// The Quote has no column; the C# throws. Never driven (no checkpoint trains
// it), so an all-zero observation is the harmless answer.
if (cls < 0 or cls >= BOT_OBS_CLASSES)
    exit;

botObsSelf(pl, ch);
botObsEnemies(pl, ch);
botObsProjectiles(ch);
botObsRays(ch);
botObsPatch(ch);
botObsGoal(ch);
