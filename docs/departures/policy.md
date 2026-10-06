# Departures: policy

Where `src/fn/policy/` differs from gg2-server's `PolicyNetwork`,
`ObservationWriter`, `ActionDecoder`, `PolicyController`, `HybridBot`,
`Handover`, `HandoverBubble` and `DecisionQuotaArbiter`, and why. The shared
departures (GM8's `random`, Player instances for slots) are in `README.md`.

## The network

- **Double precision, not float32.** The C# reads the f4 weights into `float[]`
  and accumulates in float32; GM8 has only doubles. The weights are the same
  values (f4 widens exactly); the sums differ in the last float32 bits.
  `tools/convert-policy.js` measures it on 20,000 sampled observations per
  checkpoint: max logit difference ~7e-5, argmax changed in 1 of 20,000
  (tier 0) and 0 of 20,000 (pyro). A near-tie between two logits is the only
  case it can move.
- **The summation order differs** (a halving tree instead of a running sum),
  which is the same last-bits effect, smaller.
- **No `.npz` at run time.** GM8 cannot unzip or read binary floats cheaply, so
  `tools/convert-policy.js` turns each checkpoint into ds_grid hex at build
  time (`docs/POLICY.md`). It parses the trainer's file exactly as
  `NpyFile` does and makes every refusal `PolicyNetwork.Load` makes.
- **The simulation stamp is checked by the converter, not at load.** The C#
  compares a checkpoint's `SIM_UUID` with the running build's; the GM8 game
  has no stamp. The converter pins `f10afbdadc795d77`, the gg2-server build
  whose `ObservationWriter` this module transcribes, and refuses any other
  unless given `--ignore-stamp`; the loader reports the stamp in `policy.log`.
- **A bad checkpoint is refused, not fatal.** gg2-server refuses to start on
  one, or on a malformed `[Bots] ClassPolicy`; a modal dialog on a dedicated
  GM8 server is worse than a scripted bot, so the checkpoint (or the entry) is
  skipped and `bots/policy.log` says why. A `ClassPolicy` target that names no
  loaded checkpoint leaves that class scripted; a class named twice keeps the
  first.
- **Added: a self-test and a timing at load** (`botPolicyNetLoadFile`). Neither
  exists in the C#; both exist because the forward pass leans on ds_grid
  semantics nothing can verify offline, and because the budget needs a real
  price.

## The controller

- **One controller kind, flattened.** `IMicroController` has one GML
  implementation, so a tier is a checkpoint and the per-bot controller state
  (`_ticksLeftInDecision`, the action, the decoder's aim) exists once per bot
  rather than once per tier. Exact: a tier not driving has always abandoned its
  decision (`OnHandoverOut`) or never begun one, so its state is never read
  before `OnHandoverIn` resets the aim and the first poll re-decides.
- **The zoom head is decoded nowhere** - which is also true of the C# hybrid:
  `HybridBot` issues no command for it, and no shipped checkpoint drives a
  sniper.
- **Not ported, because a live server never selects them:** `HandoverRule`
  `Distance` and `HeadSplit` (only `MacroTask` runs), a settable `Range`
  (always 150), `ScriptedCarriesIntel = false`, `HandicapSkill`, the search
  controller and its bubble, and `PolicyController`'s slot-change handling (a
  Player is its own identity; the C#'s `_slot` checks have nothing to compare).
- **The Quote is observed as all zeros** where the C# throws. No checkpoint
  trains it, so it is never driven; a throw would be a dialog.

## The decision budget

- **Priced in measured GML microseconds, from a running clock average.**
  `DecisionQuotaArbiter` charges a compile-time 7 µs and forbids reading a
  clock, to keep a headless match a pure function of its seed. A GM8 server
  has no such property to protect (its bots already draw from the game's
  shared `random`), and a GML decision costs ~100x the C#'s and varies by
  machine, so the price is measured: the forward pass timed at load, plus an
  assumed observation cost, refined by a running average of each decision's
  wall time.
- **Default budget 4000 µs a tick, not 10000.** The same key (`[Bots] Arbiter`)
  means the same thing (microseconds of controller work per tick), but 10 ms of
  GML decisions in a 33 ms tick would be most of a frame. If the measured
  decision cost ever exceeds the budget, nothing is ever admitted and every bot
  plays scripted - raise `Arbiter` (`policy.log` prints both numbers).
- **No adaptive budget.** gg2-server's `MicroBudgetController` (AIMD on tick
  pressure) is not ported; the budget is fixed.

## The observation: where the GM8 game and gg2-server's simulation can disagree

The policy was trained on gg2-server's simulation, a transcription of this
game, so every feature reads the variable the simulation transcribes. These
are the places the reading can still differ:

- **When it is read.** gg2-server observes at the start of a tick, after the
  last one ended. The bots poll from `GameServer`'s End Step hook
  (`end_step.gml`), and GM8 runs End Step instance by instance: characters and
  projectiles whose End Step runs after GameServer's (Character End Step
  snaps positions to the floor and clamps them to the map) are observed before
  that adjustment, every tick. That is the integrator's poll point; it moves
  positions and velocities by at most what one End Step changes. Verify live.
- **Weapon timers at 60 fps.** `alarm[0]` (refire) and `alarm[5]` (reload)
  count frames; they are scaled by `global.delta_factor` into the 30 Hz ticks
  the simulation's timers count, which at 60 fps can leave a half tick the
  simulation never has. At 30 fps they are the same counters. Whether a GM8
  alarm and the simulation's timer agree to the tick at the observation point
  (decrement-then-fire phase) is the simulation's claim to be a transcription;
  compare a reading live against gg2-server on the same shot if refire timing
  ever matters.
- **Rays: collision_line, then probes.** The C# marches every probe (with a
  clearance skip). Here a native `collision_line` answers a clear ray and
  brackets a blocked one before the exact probes run, and a line can differ
  from the rounded probe points by half a pixel: a ray grazing a solid cell's
  corner can report the first solid probe one or two probes late, or miss a
  probe that clips a corner the line does not touch. Elsewhere it is exact.
  The patch is exact.
- **Ties.** Two enemies or projectiles at exactly the same squared distance are
  ordered by GM8 instance order (and projectiles by kind first) rather than by
  roster slot and creation order. Exact ties only.
- **Projectiles are GM8 instances.** The nine observed objects are the
  simulation's nine `ProjectileKind`s; objects the simulation has no kind for
  (`AirBlastO`, `MineTrail`, `Pop`, `StabAnim`) are not observed, as there.
- **Grounded** asks `place_free` inside the game's own `charSetSolids()`
  bracket - the same collision set (team and intel gates, setup gates, player
  walls) the simulation's `PlaceFree` transcribes. `onground` is not used, as
  in the C#.
- **Humans** are Players with `botIsBot` false (HumansOnly gating), which
  includes the host's own Player.
- **Unchanged from the C#, said because it looks like a bug:** a cloaked spy
  is observed like anyone; the second-enemy block is fed real values although
  training saw it constant zero (gg2-server `docs/BOTS.md`, "the policy's
  untrained block"); the goal block always describes the nearest enemy.

## Wire and timing

- **The aim leaves in wire units.** The decoder's aim is quantised as
  `PlayerInput.FromAim` does (round half away from zero, clipped to 65535), the
  handicap's error added and wrapped as the C#'s `ushort` cast, and returned as
  that unit's exact degrees, so `botPoll`'s own quantisation reproduces it.
- **Bubbles** go out with `botSendByte` - there is no per-tick command buffer
  to overflow - and trail their handover by however the integrator orders
  `botHybridPollCommands` against `botHybridPoll` (a tick, on gg2-server).
