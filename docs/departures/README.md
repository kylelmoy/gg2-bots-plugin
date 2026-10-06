# Departures from the C#

One file per module (`nav.md`, `path.md`, `combat.md`, `objective.md`,
`policy.md`, `brain.md`). Each entry: what the C# does, what the GML does
instead, and why - usually a GM8 limit (no NaN, no short-circuit, cost of an
interpreted loop) or a difference between gg2-server's simulation and the real
game's objects. A behaviour change that is not written down here is a bug.

Shared by every module:

- **Random numbers come from GM8's own generator**, not a per-bot seeded
  stream (`ScriptedBot.Random`). The game seeds weapon spread per shot and
  restores the seed afterwards (`doEventFireWeapon.gml`), so bot draws cannot
  desynchronise clients, which was the C# rule's purpose; what is lost is
  per-bot reproducibility, which only gg2-server's measurement harness used.
- **Identity is the `Player` instance, not a roster slot**, because roster
  indices compact when anyone leaves (PORTING.md, "Identity").
