// navGraphKey(map, area, md5): NavCache.Key - graph file stem
// `<name>[_<md5>]_a<area>`; chars outside [A-Za-z0-9_-] become `_`.
// Departure: the md5 argument (non-empty for custom maps) is not in the C#.
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
