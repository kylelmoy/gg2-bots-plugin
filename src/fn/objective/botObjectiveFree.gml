// botObjectiveFree(player): the per-bot objective state owns no ds_ structures
// (the spot search's scratch is global and reused by every bot), so there is
// nothing to free. Present so botDetach can treat every module alike.
