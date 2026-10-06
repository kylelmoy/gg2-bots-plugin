// navGraphAnchorColumn(worldX): NavGraph.AnchorColumn (navAnchorCol.gml) - the
// anchor column a character standing at this world x occupies.
//
// The - BoxW/2 is the half-box offset between a node's span (the box's left
// edge) and a character's x (the sprite's centre). floor, not div: div
// truncates toward zero and would put x < 0 one column too high.
return floor(argument0 / NAV_CELL_SIZE) - (NAV_BOX_W div 2);
