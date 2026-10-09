// navGraphAnchorColumn(worldX): NavGraph.AnchorColumn - anchor column for a
// character at worldX. floor, not div (div truncates toward zero).
return floor(argument0 / NAV_CELL_SIZE) - (NAV_BOX_W div 2);
