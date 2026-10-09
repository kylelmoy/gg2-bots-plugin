// navGenWrite(): NavCacheWriter.Serialise to <key>.txt in global.botNavDir,
// through a temporary name so the map check never reads half a file. Then
// frees everything the build held; the map check loads the file. False if the
// file could not be written.
var path, tmp, f, ok;
path = global.botNavDir + global.navGenKey + ".txt";
tmp = path + ".tmp";
f = file_text_open_write(tmp);
ok = (f >= 0);
if (ok)
{
    file_text_write_string(f, "navgraph " + string(NAV_CACHE_VERSION));
    file_text_writeln(f);
    file_text_write_string(f, string(global.navGenW) + " " + string(global.navGenH) + " " + string(global.navGenNodeCount) + " " + string(global.navGenWritten));
    file_text_writeln(f);
    file_text_write_string(f, ds_grid_write(global.navGenSortedNodes));
    file_text_writeln(f);
    file_text_write_string(f, ds_grid_write(global.navGenSorted));
    file_text_writeln(f);
    file_text_close(f);
    if (file_exists(path))
        file_delete(path);
    file_rename(tmp, path);
    ok = file_exists(path);
}
ds_grid_destroy(global.navGenSortedNodes);
global.navGenSortedNodes = -1;
return ok;
