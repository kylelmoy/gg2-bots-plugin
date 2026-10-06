# Porting gg2-server's bot layer to plugin GML

The contract every part of the port is written against. The bot layer is
gg2-server's (`D:/Code/gg2-server/src/GG2.Bots/`, C#): the scripted bot, the
learned policy and the hybrid that hands between them. This repository is that
layer re-expressed as GML that runs inside the stock Game Maker 8 game, as a
local plugin. **The C# is the specification.** Where the GML must differ, the
difference is written down in the function's header comment and in
`docs/DEPARTURES.md`.

## Sources, in order of authority

| What | Where |
|---|---|
| The behaviour to reproduce | `D:/Code/gg2-server/src/GG2.Bots/*.cs`, `src/GG2.Protocol/{BotConstants,NavConstants}.cs`. The doc comments explain every decision; read them. `docs/BOTS.md` and `docs/TRAPS-BOTS.md` there are the long form. |
| How C# world state maps to the GM8 game's own variables | The C# **simulation** (`src/GG2.Simulation/`) is a transcription of the GM8 game, and nearly every field there names the GML it came from in a comment. `docs/SOURCEMAP.md` there maps files. The game itself: `D:/Code/Gang-Garrison-2/Source/gg2/` (scripts are `.gml`; object events are XML under `Objects/**.events/`, with the code XML-escaped inside `<argument kind="STRING">`). |
| The original GML bots this C# layer was ported FROM | `C:/Users/kylel/AppData/Local/Temp/claude/D--Code-gg2-bots-plugin/67fa66a0-b286-49f5-84e0-3855b2924e70/scratchpad/fork-bots/` (a fork of the game, branch `bot-route-variety`; read-only). Older than the C# - the C# fixed and extended a great deal since - but it reads the real GM8 objects, so it is the best guide to **which game variable** a C# field is (`Character.onground`, `.intel`, `.zoomed`, `Rocket.ownerPlayer`, ...). Many C# doc comments cite these scripts by name (`botPathKeys`, `botAimSolve`). Never port its *logic* where the C# differs. |
| GM8 GML dialect and its traps | `D:/Code/gg2-agent/GML.md` - **read it before writing any GML**. No ternary, no short-circuit `and`/`or`, `-1` is `self`, `round` is banker's, `var` must not shadow a builtin (`x`, `y`, `score`, `other`, `direction`, `speed`, ...), no `\n` escapes, 2-D arrays max. |

## How plugin code is written

A plugin cannot define scripts. `tools/botc.js` (read its header) compiles each
`src/fn/**/<name>.gml` into the User Event of an object of its own and rewrites
calls into `event_perform_object`. The rules it enforces:

- **One function per file**, `src/fn/<module>/<name>.gml`, name matching
  `^(bot|nav)[A-Z]`. Arguments are `argument0`..`argument15`; `return expr;` and
  `return;` work.
- **A call is a whole statement**: `f(a);`, `x = f(a);` or `return f(a);`.
  Never inside a condition, an expression or another call's arguments - hoist
  it into a local first. The build refuses anything else and says where.
- **Extra results** go in `global.botRet<Name>` (e.g. `global.botRetAim`),
  set by the callee and read by the caller **immediately** after the call,
  before any other call can overwrite them. `global.botRet` is the main result.
- **`self` inside a function is the caller**, exactly as with a script.
- **Constants** are `src/constants/*.txt` (`NAME value`), inlined at build
  time. `generated.txt` is every `NavConstants`/`BotConstants` value under its
  original GML name (`BOT_REPLAN_TICKS`, `NAV_CELL_SIZE`, ...; regenerate with
  `node tools/gen-constants.js`, never edit). `keys.txt` has the key bits
  (`BOT_KEY_LEFT` etc). A module's own constants (C# `private const`) go in
  `src/constants/<module>.txt`, named `BOT_<...>` / `NAV_<...>`.
- `var` locals are per call. Arrays: a local array is not safe to rely on;
  use a `global.bot<Module>Tmp...` array or a ds_ structure for scratch.
- GML errors at run time are modal dialogs on the host. Guard every instance
  read: a dead player's `object` is `-1`, which is `self`; compare `!= -1`,
  never `instance_exists`.

Build and lint: `node tools/build.js --stub-missing` (lint only; any `bot*`/`nav*`
function called but not yet written by another module is stubbed, and listed).
`node tools/build.js` is the full build and requires everything to exist.
**Do not launch the game or install into it** - the live game is one shared
resource and the integrator runs it.

## Identity: what a C# parameter becomes

| C# | GML |
|---|---|
| `int slot` (a roster index) / `world.Player(slot)` | the bot's **`Player` instance id**. Roster indices compact when anyone leaves; an instance id does not. Pass `player`. |
| `world.Character(slot)`, `in CharacterState self` | `player.object`, the `Character` instance, **`-1` when dead**. Functions take it as an argument (`char`) when the C# took `self`. |
| `world.IsAlive(slot)` | `player.object != -1` |
| `int tick` | `global.botTick` (30 Hz virtual ticks since the server started). Do not pass it. |
| `ref GmlRandom random`, `Random.Next(n)` | GM8's own `random(n)` / `irandom(n)` / `choose(...)`. Weapon spread is seeded per shot by the game (`doEventFireWeapon.gml` saves and restores the seed), so a bot drawing here cannot desynchronise clients. (DEPARTURES.md: not reproducible per bot.) |
| `Gml.PointDistance`, `Gml.PointDirection`, `Gml.Round`... | the GM8 builtins `point_distance`, `point_direction`, `round` (banker's - which is what `Gml.Round` reproduces) |
| `world.Collision` (terrain queries) | object-typed collision functions against the live map: `collision_point(x, y, CustomMapO, true, true)` etc. **Never `place_free`/`collision_point_solid`** - `Obstacle.solid` is only true inside a character's own step (GML.md). `collision_line_bulletblocking` is safe anywhere. |
| an iteration over slots | `with (Player)` or `with (Character)`; inside, `other` is the caller. Characters are `Character` and its class children (`Scout`, ...); test `object_is_ancestor`/`player.class` as the C# tests `Class`. |
| a projectile / sentry state | the game's own instances (`Rocket`, `Mine`, `Shot`, `Flame`/`BurningProjectile`, `Needle`, `Sentry`, ...) and their fields; find the mapping in GG2.Simulation's comments and the fork. |
| `PlayerInput` (keys + aim) | keys in `global.botRet` (bits `BOT_KEY_*`), aim in `global.botRetAim` (degrees, GM8's direction convention), aim distance in `global.botRetAimDist` (pixels). `botPoll` quantises both exactly as `processClientCommands` does. |
| `PlayerCommand` (drop intel, zoom, build, eat, bubble) | `botSendByte(player, COMMAND, payloadOrMinus1)` - a real client command on the bot's own socket, handled by the game's `processClientCommands` next tick. |
| a `List<int>` / `HashSet` / `Dictionary` | `ds_list` / `ds_map` (keys as reals) owned by whoever owns the C# object; freed in its `...Free` function. GM8 has no GC. |
| `double.NaN` | a separate `...Valid` boolean, or a sentinel documented beside it. GM8 has no NaN. |

## Naming: derived, so nobody has to ask

Every C# member has exactly one GML name, derived mechanically, so a module can
call into another module that is being written at the same time.

**Functions**: `<prefix><Member>`, where the prefix is the C# class's below and
`<Member>` is the C# method or computed property, unchanged:
`NavGraph.NodeFromWorld` -> `navGraphNodeFromWorld`, `BotTargeting.ClassRange`
-> `botTargetingClassRange`, `PathFollower.Step` -> `botFollowerStep`. An
overload gets a suffix naming what distinguishes it, documented in its header.

**Per-bot state** (C# instance fields/properties of an object there is one of
per bot) is an instance variable **on the bot's `Player`**: `<prefix><Field>`,
e.g. `BotPathState.HasGoal` -> `botPathHasGoal`, `BotCombatState.TargetAt` ->
`botCombatTargetAt`. A field that is itself a struct flattens:
`BotCombatState.Target.Exists` -> `botCombatTargetExists`. Each owner provides
`<prefix>Init(player)` (sets every field it owns; called once when the bot
joins) and `<prefix>Free(player)` (frees its ds_ structures; called when the
Player is destroyed). Init must set *every* field another module may read.

**Shared state** (one per server, e.g. the graph, the occupancy counts, the
policy weights) is `global.<prefix><Field>`.

| C# class | prefix | owner |
|---|---|---|
| `NavGraph`, `NavTypes`, `NavCache`, `NavQuery` | `navGraph` (`NavQuery` is passed as arguments, see below) | nav |
| `NavSearch` | `navSearch` | nav |
| `NavDistances`, `NavDistanceSet`, `NavDistanceFile` | `navDist` | nav |
| `BotOccupancy` | `botOccupancy` | nav |
| `BotLanes` | `botLanes` | nav |
| `BotPathState` | `botPath` | path |
| `PathFollower` (all three files) | `botFollower` | path |
| `JumpModel`, `RocketModel`, `StickyModel`, `BotArc` | `botJump`, `botRocket`, `botSticky`, `botArc` | path |
| `BotStep` | `botStep` | combat |
| `BotCombatState` | `botCombat` | combat |
| `BotCombat` | `botCombat` | combat |
| `BotTargeting`, `BotVisibility`, `BotAim`, `BotReflex`, `BotSuppress`, `BotStab`, `BotMines`, `BotAlly` | `botTargeting`, `botVisibility`, `botAim`, `botReflex`, `botSuppress`, `botStab`, `botMines`, `botAlly` | combat |
| `BotClassKeys`, `BotClassProfile` | `botClassKeys`, `botClassProfile` | combat |
| `BotSkill` | `botSkill` (per-bot knobs: `botSkill<Knob>` on the Player) | combat |
| `BotObjective`, `BotGoalSpot`, `BotRoles`, `SpawnPoints` (GG2.Maps) | `botObjective`, `botGoalSpot`, `botRoles`, `botSpawns` | objective |
| `PolicyNetwork`, `ObservationWriter`, `ActionDecoder`, `PolicyController` | `botPolicyNet`, `botObs`, `botActionDecoder`, `botPolicy` | policy |
| `HybridBot`, `Handover`, `HandoverBubble` | `botHybrid`, `botHandover`, `botBubble` | policy |
| `ScriptedBot` | `botScripted` | brain (integrator) |
| `BotPopulation`, `BotPopulationService`, the join/socket plumbing | `bot...` in `src/fn/server/` | brain (integrator) |

`NavQuery` is passed as six arguments in this order wherever the C# passes one:
`team, hasIntel, setupGatesClosed, canDoubleJump, canRocketJump, canStickyJump`.

Return structs: `NavSnap` from `navGraphSnapObjective` returns `Node` in
`global.botRet` and `global.botRetDrop`, `global.botRetGoalX`,
`global.botRetGoalY`. The general rule: the struct's fields as
`global.botRet<Field>`, and `global.botRet` holds the field a caller most
often tests (`Found`, `Node`, `Exists`). Document it in the header.

## The nav graph in memory

Owned by nav; read directly by path and objective for speed (a `ds_grid_get`
is a native call; a function call is not free). Valid while
`global.botNavReady` is true; replaced on every map change.

| global | what |
|---|---|
| `global.botNavReady` | a graph is loaded for the current map and area |
| `global.botNavNodes` | ds_grid, `NAV_NODE_FIELDS` wide x node count: `ds_grid_get(global.botNavNodes, NAV_NODE_X0, n)` |
| `global.botNavEdges` | ds_grid, `NAV_EDGE_FIELDS` wide x edge count, edges grouped by `From` as in the file |
| `global.botNavNodeCount`, `global.botNavEdgeCount` | |
| `global.botNavEdgeStart` | ds_grid 2 x nodes: `[0, n]` first edge index from `n` (-1 if none), `[1, n]` how many |
| `global.botNavRowStart` | ds_grid 1 x (mask height + 2): first node index on that mask row, or -1 (`NavGraph._rowStart`) |
| `global.botNavMaskW`, `global.botNavMaskH` | |
| `global.botNavMap`, `global.botNavArea` | what the graph is for |

The files (`bots/nav/<key>.txt` and `<key>.dist`) and the generator that
writes them are described in `docs/NAVFILES.md`.

## Order of a tick (who calls what)

`hooks/GameServer/end_step.gml` runs after the game's own end step, once a
frame; on a 30 Hz virtual tick it advances `global.botTick`, runs the map
check (`botNavMapCheck`, nav) and the population (`server/`), and calls
`botPoll(player)` for each bot, which calls `botThink(player, char)` - the
integrator's `ScriptedBot`/`HybridBot` composition - and writes the keys and
aim onto the character the way a client's INPUTSTATE is written. `botAttach`
and `botDetach` (integrator) call every module's `Init`/`Free`.
