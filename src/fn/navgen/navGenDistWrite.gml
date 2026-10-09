// navGenDistWrite(): PluginDistFile.Write to <key>.dist (docs: NAVFILES.md),
// through a temporary name. The tables were appended in ascending key order.
// False if it could not be written.
var path, tmp, out, t;
path = global.botNavDir + global.navGenKey + ".dist";
tmp = path + ".tmp";
out = buffer_create();
write_string(out, "GG2BDIST");
write_uint(out, NAV_DIST_VERSION);
write_uint(out, global.navGenDistNodes);
write_uint(out, global.navGenDistEdges);
write_uint(out, global.navGenDistPresent);
write_uint(out, ds_list_size(global.navGenDistTables));
for (t = 0; t < ds_list_size(global.navGenDistTables); t += 1)
    write_buffer(out, ds_list_find_value(global.navGenDistTables, t));
if (file_exists(tmp))
    file_delete(tmp);
write_buffer_to_file(out, tmp);
buffer_destroy(out);
if (!file_exists(tmp))
    return false;
if (file_exists(path))
    file_delete(path);
file_rename(tmp, path);
return file_exists(path);
