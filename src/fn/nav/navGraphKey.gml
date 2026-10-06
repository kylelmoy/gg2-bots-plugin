// navGraphKey(map, area, md5): NavCache.Key - the filename stem for a map and
// area's graph files (docs/NAVFILES.md, "The key").
//
// The map NAME is the identity: serverGotoMap leaves currentMapMD5 empty for
// every internal map, so keying on the MD5 would give every shipped map one
// entry. Every character outside [A-Za-z0-9_-] becomes an underscore.
//
// Overload: the C# has no md5 argument (it serves built-in maps only). Here a
// non-empty md5 (global.currentMapMD5) goes between the name and the area - `<name>_<md5>_a<area>` -
// so two different custom maps under one name never share a graph.
var name, hash, safe, i, c, code;
name = argument0;
hash = argument2;
safe = "";
for (i = 1; i <= string_length(name); i += 1)
{
    c = string_char_at(name, i);
    code = ord(c);
    if ((code >= 97 && code <= 122) || (code >= 65 && code <= 90) || (code >= 48 && code <= 57) || c == "_" || c == "-")
        safe += c;
    else
        safe += "_";
}
if (hash != "")
    safe += "_" + hash;
return safe + "_a" + string(argument1);
