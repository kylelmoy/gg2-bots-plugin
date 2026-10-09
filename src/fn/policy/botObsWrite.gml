// botObsWrite(player, char): ObservationWriter.Write - the observation
// (layout v2, 211 rows) into global.botObsGrid; default AgentGoal.
// Grid is cleared first; writers set only non-zero rows.
var pl, ch, cls;
pl = argument0;
ch = argument1;
ds_grid_clear(global.botObsGrid, 0);
global.botObsEnemy0 = noone;
global.botObsEnemy0D = -1;

if (ch < 0)
    exit;
cls = pl.class;
// Quote: all zeros (the C# throws)
if (cls < 0 or cls >= BOT_OBS_CLASSES)
    exit;

botObsSelf(pl, ch);
botObsEnemies(pl, ch);
botObsProjectiles(ch);
botObsRays(ch);
botObsPatch(ch);
botObsGoal(ch);
