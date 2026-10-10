# The policy module

gg2-server's learned policy and the hybrid that hands the wheel to it
(`PolicyNetwork`, `ObservationWriter`, `ActionDecoder`, `PolicyController`,
`HybridBot`, `Handover`, `HandoverBubble`, and `DecisionQuotaArbiter` in the
role of the arbiter), as GML in `src/fn/policy/`. The C# is the spec;
`docs/departures/policy.md` lists where this differs and why.

Shipped: `combat` drives scout, soldier, demoman and heavy; `pyro` drives
pyro (converted from gg2-server's `tier0_combat4_s2` and `tier2_pyro_rest3_s0`;
`tools/convert-policy.js` names them); sniper, spy, engineer and medic stay
scripted (gg2-server `checkpoints/README.md`).

## API for the integrator

| call | when | what |
|---|---|---|
| `botPolicyNetLoad()` | server start, after `botConfigLoad` | loads every `bots/policy/*.txt`, self-tests and times each, resolves `[Bots] ClassPolicy`, reads `[Bots] Arbiter`; writes `bots/policy.log`. `global.botMode == "scripted"` loads nothing. Returns the tier count. |
| `botPolicyNetFree()` | server stop | destroys every grid it made |
| `botHybridInit(player)` | bot joins | sets every per-bot field below |
| `botHybridFree(player)` | Player destroyed | nothing to free (no per-bot ds_); call it anyway |
| `botHybridPoll(player, char)` | every 30 Hz tick, per bot | `HybridBot.Poll`. `char` is `player.object` or a negative id when dead. Calls `botScriptedPoll(player, char)` itself, every tick. Returns keys in `global.botRet`, aim degrees in `global.botRetAim`, aim distance in `global.botRetAimDist`. |
| `botHybridPollCommands(player)` | every tick, per bot | `HybridBot.PollCommands`: calls `botScriptedPollCommands(player)`, then sends a pending handover bubble with `botSendByte(player, CHAT_BUBBLE, image)`. gg2-server runs it before `Poll`. |

Calls into other modules: `botScriptedPoll`, `botScriptedPollCommands`
(brain), `botAllyStillValid(player, ally)` (combat; `BotAlly.StillValid` with
the world dropped), `botSendByte` (server). Fields read on the Player:
`botScriptedWantsToEngage` (brain); `botCombatTargetExists`,
`botCombatTargetAt`, `botCombatAlly`, `botSkillFireDelayTicks`,
`botSkillAimInterval`, `botSkillHoldFireChance`, `botSkillPolicyAimErrorDeg`
(combat); `botIsBot`, `class`, `team`. Globals read: `global.botMode`,
`global.botEngagesBots`, `global.botHandoverBubbles`, `global.botDir`,
`global.botTick`.

Per-bot fields it owns (all set by `botHybridInit`): `botHybridDriving` (the
tier holding the wheel, -1 for the scripted layer), `botHybridBubble`,
`botHybridBubbleShown`, `botHybridBubbleSentAt`, `botHybridCommandPolls`,
`botHybridHandicapAim`, `botHybridHandicapHoldFire`,
`botHybridHandicapTicksLeft`, `botHybridMicroDrove`,
`botHybridDecidedThisPoll`, and the counters `botHybridMicroTicks`,
`botHybridMicroDecisions`, `botHybridScriptedTicks`, `botHybridScriptedPolls`
(`ScriptedPolls == MicroTicks + ScriptedTicks` is the C#'s invariant that the
macro layer never stops thinking); `botPolicyTicksLeftInDecision`,
`botPolicyDecidedThisPoll`, `botPolicyActionHorizontal`/`Jump`/`Down`/`Fire`/
`AimDelta`/`Zoom`, `botActionDecoderAim`.

Shared state: `global.botPolicyNetCount` and per tier `n`:
`global.botPolicyNetLabel[n]`, `...Uuid[n]`, `...Repeat[n]` (action repeat),
`...Layers[n]`, `...Trained[n, class]`, `...Drives[n, class]`, `...Cost[n]`
(µs, measured), the grids `...W[n, L]`, `...B[n, L]`, `...T[n, L]`;
`global.botObsGrid` (the last observation, 1 x 211);
`global.botPolicyNetHead[0..5]` (the last argmax);
`global.botArbiterBudget`, `global.botArbiterSpent`, `global.botArbiterTick`;
`global.botPolicyNetReport` (what `policy.log` says).

There is one controller kind in GML, so `IMicroController` is flattened: a
tier IS a policy checkpoint, and the per-bot controller state exists once, not
once per tier - a tier that is not driving has always abandoned its decision
(`OnHandoverOut`) or never started one, so only the driving tier's cadence and
aim are ever live.

## The file: `bots/policy/<label>.txt`

Made by `node tools/convert-policy.js` (defaults: every `.npz` in
gg2-server's `checkpoints/`, out to `data/policy/` (committed), which `tools/build.js`
copies to `Plugins/bots/policy/`). The label is the checkpoint's file name
without `.npz`, the name `[Bots] ClassPolicy` uses. CRLF text, one field a
line:

```
gg2policy
1                         format version (BOT_POLICY_FORMAT)
<label>
<policy version>          meta[0]
<simulation uuid>         meta[1]
<action encoding>         meta[2], must be 2
<observation layout>      meta[3], must be 2
3,2,2,3,15,2              meta[4], the head shape
211                       meta[5], observation length
4                         meta[6], action repeat
0,1,3,6                   the trained classes as GM8 class numbers (CLASS_*)
SCOUT,SOLDIER,DEMOMAN,HEAVY   meta[7] as written (the default set when absent)
3                         layer count
then per layer L:
<inputs>
<outputs>
<weights: ds_grid hex>
<bias: ds_grid hex>
then:
<test observation: ds_grid hex, 1 x 211>
<expected logits: ds_grid hex, 27 x 1>
<expected argmax per head, e.g. 1,0,0,1,7,0>
```

A ds_grid hex line is what GM8's `ds_grid_write` produces and `ds_grid_read`
takes: `uint32 601` (the grid tag), `uint32 width`, `uint32 height`, then
`width * height` cells **column-major** (cell `(x, y)` at index
`x * height + y`), each 16 bytes: `uint32 0` (the cell is a real), the
`float64` value, `uint32 0`; little-endian, upper-case hex. Verified against
gg2-server's `NavCache.ReadGrid` and the real nav files in `gg2-server/nav/`.

Layer orientation alternates (see the forward pass): layer `L` even is
`outputs` wide and `inputs` high, cell `(j, i) = W[i][j]`, with a bias row
(`outputs x 1`); layer `L` odd is `inputs` wide and `outputs` high, cell
`(i, j) = W[i][j]`, with a bias column (`1 x outputs`). `W` is numpy's `w<L>`,
`inputs x outputs`.

The converter refuses what `PolicyNetwork.Load` refuses: fewer than seven
metadata fields, a simulation stamp other than `f10afbdadc795d77` (the
gg2-server build whose `ObservationWriter` this module transcribes;
`--ignore-stamp` is the C#'s `ignoreSimulationStamp`), action encoding or
layout other than 2, a length other than 211, a different head shape, layers
that do not chain or do not end at 27. It reads the trainer's own pickle the
way `NpyFile.ReadStrings` does, and f4 weights exactly. `botPolicyNetLoadFile`
checks the same fields again (not the stamp: the GM8 game has none to compare)
and the grid dimensions `ds_grid_read` leaves.

**The test vector is checked live.** At load the GML forward pass runs on the
file's observation and must reproduce the converter's logits (relative error
<= 1e-6) and argmax, or the checkpoint is refused and `policy.log` says why.
That is what establishes, on the engine itself, that the ds_grid region
functions behave as the forward pass assumes.

## The forward pass (`botPolicyNetAct`)

An interpreted multiply-add loop over 211x64 + 64x64 + 64x27 = 19,328 weights
would cost ~30 ms. Instead each layer is a handful of native ds_grid region
calls on a scratch grid `T` shaped like the weights:

1. the input vector is copied in as `T`'s first column (row, on odd layers);
2. it is replicated across all `outputs` columns by doubling copies
   (`ds_grid_set_grid_region` of the filled part onto the next part: 1, 2, 4,
   ... columns);
3. `ds_grid_multiply_grid_region(T, W, ...)`: now `T[j, i] = x[i] * W[i][j]`;
4. the `inputs` rows are summed onto row 0 by halving: rows `h-k..h-1` are
   added onto rows `0..k-1` with `ds_grid_add_grid_region`, `k = h div 2`,
   until one row remains - `ceil(log2 inputs)` calls;
5. the bias row is added (one call), then ReLU clamps each output (the only
   per-element work, hidden layers only).

Even layers read down a column and leave their outputs along row 0; odd layers
read along a row and leave a column. So each layer's result is already laid out
the way the next one reads it - no transpose. The argmax per head is
`ds_grid_get_max` then `ds_grid_value_x`/`_y` over the head's 3/2/2/3/15/2
cells.

**Estimated cost** for 211 -> 64 -> 64 -> 27: 58 bulk native calls (layer 0:
1 copy + 6 replicate + 1 multiply + 8 halvings + 1 bias; layer 1: 15; layer 2:
14; argmax: 12) moving about 60,000 cells natively, plus 128 ReLU reads and
about 64 writes. At ~1.5 µs of interpreter overhead per native call and a few
ns per native cell: roughly 0.4-0.7 ms a forward pass. The observation adds
roughly 0.2-0.6 ms (below). A decision is taken once per action repeat (4
ticks) per bot holding the wheel. The real number is in `policy.log`: each
tier's forward pass is timed at load.

## What the observation reads

`botObsWrite` (with `botObsSelf`, `botObsEnemies`, `botObsProjectiles`,
`botObsRays`, `botObsPatch`, `botObsGoal`), layout v2, 211 floats, every block
in the C#'s order and scale. The game variables, all checked against the game
source:

| feature | GM8 source | set by |
|---|---|---|
| own class, an enemy's class | `Player.class` | the game; `CLASS_*` equal `PlayerClass` ordinals |
| hp | `Character.hp`, over the class's `maxHp` | class Create events (the table in `botObsInit` matches them) |
| velocity | `Character.hspeed`, `vspeed` | GM8 motion |
| grounded | `!place_free(x, y + 1)` inside `charSetSolids()`/`charUnsetSolids()` | as Character Begin Step's `obstacleBelow` |
| aim | `Character.netAimDirection * 360 / 65536` | `processClientCommands` INPUTSTATE; `botPoll` for bots |
| ammo | `currentWeapon.ammoCount` / max | each weapon's Create |
| reload, refire | `currentWeapon.alarm[5]`, `alarm[0]`, times `global.delta_factor` | the weapons' fire events; `Weapon` Create |
| ready | `currentWeapon.readyToShoot` | `Weapon` Create and Alarm 0 |
| engineer's special | `Character.nutsNBolts` / 100 | Character Create |
| enemies | `with (Character)`, other `player.team` | |
| projectiles | `Shot`, `Rocket`, `Mine`, `Flame`, `Needle`, `Flare`, `BladeB`, `Bubble`, `StabMask` (`ProjectileKind` 1..9): `x`, `y`, `hspeed`, `vspeed`, `team` | `createShot` sets `team`; `StabMask`, the loose flames of an extinguish and client-side mines set it right after `instance_create` |
| rays, patch | precise `collision_point`/`collision_line`/`collision_rectangle` against `CollisionMapO` | `CustomMapRoom` creates `CustomMapO` (its child) at (0, 0) with the map's collision sprite at 6x |

Cost: the self block ~20 calls; enemies one `with (Character)` pass; each
projectile kind one `instance_number` (plus one `instance_nearest` when any
exist), and an interpreted pass only over a kind with something within 400 px;
rays one `collision_line` for a clear ray, ~9 calls for a blocked one; the
patch one `collision_rectangle` when there is no terrain near, else one per row
plus 8 points per row with terrain in it.

## The decision budget

`DecisionQuotaArbiter`'s semantics with GML prices: `global.botArbiterBudget`
microseconds of decisions a tick (`[Bots] Arbiter`, default
`BOT_ARBITER_DEFAULT_US` = 4000), spent in poll order, most capable tier first;
a bot whose decision does not fit plays the tick on the scripted layer. A
decision is charged `global.botPolicyNetCost[tier]`: the forward pass timed at
load plus `BOT_POLICY_OBS_COST_US`, then refined by a running average of each
real decision's wall time (`current_time` is coarse, so one sample is usually
0 or a clock tick, but its expectation is the true cost). Only decisions are
charged, not the held ticks between them.
