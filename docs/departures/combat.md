# combat: departures from the C#

Each entry: what the C# does, what the GML does, why.

## Identity and state

- **Targets name instances.** `BotTarget.Slot` is a roster slot for a
  character and a sentry's owner slot for a sentry, and meaningless (-1) for a
  generator. `botCombatTargetSlot` is the target's Player instance, the Sentry
  instance, or the Generator instance. A sentry is a thing in its own right in
  GM8, so naming it beats going through its owner (an owner can leave while
  the sentry dies a tick later). Same for `botCombatAlly`: a Player, `noone`
  for `BotAlly.None`.
- **`botCombatStagger` is a join counter**, not the roster slot. Slots
  compact; a phase only has to differ between bots, not be any particular
  number.
- **`BotTarget` and `AimSubject` are flattened** into
  `botCombatTarget{Exists,Kind,Slot,X,Y,Visible}` and
  `botCombatAimSubject{Kind,Slot,X,Y,Visible}`. `Exists` is a stored field
  (kept in step wherever the kind changes) because other modules read it.
- **The class is `player.class`**, where the C# reads the character's class.
  Changing class kills the character (`processClientCommands`,
  `PLAYER_CHANGECLASS`), so the two agree whenever a character exists.

## Targeting

- **Ties in `botTargetingFind` go to `ds_priority`**, not to the lower slot
  (the C#'s stable insertion sort). The C# notes the reference had the same
  unspecified rule; only reproducibility is lost, which only gg2-server's
  harness used. `botAllyFind` ties go to the earlier instance in `with` order
  rather than the lower slot, for the same reason.
- **Map objects are aimed at the centre of their live `bbox_*`**, where the
  C# uses `Sentries.BodyBox` / `Generators.BodyBox` (its transcription of the
  same thing). The mine test uses the engine's own `distance_to_object`,
  which is what the C#'s `ReportedBox` reproduces.
- **`LastDamageSource == SentryTurret`** is
  `lastDamageSource == global.DAMAGE_SOURCE_SENTRYTURRET`: the game registers
  damage sources as globals (`createGlobalDamageSource`).

## Aim

- **`AngleDelta` and the slew's normalisation use `floor`, not `mod`**, so
  they are exact on real operands whatever GM8's `mod` does with fractions.
  The results equal the C#'s for every input, including -180 for exactly
  opposite.
- **`botAimLead` inlines `FallPredict`** in its loop (identical arithmetic)
  so a solve costs no extra calls; `botAimFallPredict` remains for the stab
  window.
- **The perceive refresh compares the subject by value**, as the C#'s record
  equality does (`AimSubject == Target` compares kind, slot, x, y and
  visible). The C#'s Target x/y are refreshed every tick, so a visible target
  that has moved is re-perceived every tick regardless of
  `botSkillPerceiveTicks`. Ported as written - it is the shipped, tuned
  behaviour - but it reads like an accident (the reference compared instance
  ids); flagged for gg2-server rather than changed here.
- **Fuzzy comparisons** (`Gml.GreaterOrEqual` etc. in `BotStab`, `BotMines`)
  are GM8's own native comparisons here, which is what the C# reproduces.

## Reflexes

- **`BotReflex.Roll` is not SplitMix64.** GM8 has no 64-bit integers, so the
  per-projectile miss is `frac(|sin(proj * 12.9898 + player * 78.233)| *
  43758.5453)` of the two instance ids. Same properties: fixed per projectile
  and bot, different between bots, draws nothing from `random`.
- **No 32-projectile scan cap.** The C# gathers at most `Scan` (32)
  projectiles inside the radius; `with (Rocket)` etc. visit every one. It only
  differs past 32 in range, where the C# could only decline.
- **A Flare/Mine whose owner is gone or dead has travelled 1e9 px**, the C#'s
  `double.MaxValue`.

## Suppression

- **The BFS frontier is a `ds_list` with a head index and `seen` a
  `ds_map`**, both one per server (`global.botSuppressQueue`,
  `global.botSuppressSeen`), cleared per call, where the C# uses stack arrays
  with a linear `Contains`. Same order, same caps.
- **`EdgePassable` is asked only for a gated edge** (`NAV_GATE_NONE` is
  always passable, `GatePassable`'s first case), saving a call per edge.
- **The node centre is computed here** (`botSuppressCentre`, with
  `BOT_COMBAT_STAND_FEET` = `NavGraph.FeetOffset`) rather than through nav's
  `ColumnWorldX`/`StandY` functions: two lines of arithmetic against the grids
  nav publishes.

## Not departures, but worth knowing

- The medic's `Heals` and `SpecialIsFire` tests in `botCombatStep` are
  written as `class == CLASS_MEDIC` inline, the whole of both table rows.
- `BotVisibility.CanSee` is inlined in the candidate loops (`with
  (Character)`) rather than called per character; `botVisibilityCanSee` is
  the one copy to keep them in step with.
