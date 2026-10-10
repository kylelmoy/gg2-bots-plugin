# gg2-bots

Gang Garrison 2 server plugin that adds bots.
Clients do not need a plugin to connect.

The bots are a combination of scripted behavior + a policy trained with reinforcement learning.

This is a GML port of the bot implementation in [kylelmoy/gg2-server](https://github.com/kylelmoy/gg2-server) (v1.0.1).

## Install

1. Download `gg2-bots.zip` from the latest release on the
   [releases page](https://github.com/kylelmoy/gg2-bots-plugin/releases/latest).
2. Extract it into the Gang Garrison 2 game folder (next to `Gang Garrison 2.exe`).
   It adds `Plugins/bots.gml` and `Plugins/bots/`.
3. Host a game, configure bots on the Bots settings tab.

## Settings

The Bots tab of the Host Game menu edits some common options (`Enabled`, `FillToPlayers`,
`MaxBots`, `Difficulty`, `NamePrefix` and `Debug`). All other settings can be set in `gg2.ini`.

| `[Bots]` | Default | |
|---|---|---|
| `Enabled` | 1 | 0 turns the plugin off without uninstalling it |
| `FillToPlayers` | 8 | bots are added until people + bots reach this |
| `MaxBots` | 8 | never more bots than this |
| `MinHumans` | 1 | no bots at all until this many people are connected |
| `Difficulty` | 5 | 1 (easy) to 5 (hard) |
| `NamePrefix` | `[BOT] ` | bots are named prefix + class; quote it to keep a trailing space |
| `Mode` | `policy` | `scripted` never hands the wheel to the policy |
| `EngagesBots` | 0 | 1: the policy also takes over against other bots, not only against people (costs CPU for nobody's benefit) |
| `Arbiter` | 10000 | microseconds of policy decisions allowed per tick; past it, bots stay scripted that tick |
| `ClassPolicy` | | per-class policy override, e.g. `Pyro=scripted` |
| `HandoverBubbles` | 0 | a bot shows the z1/z2 chat bubble when the policy takes or returns the wheel (debugging) |
| `Debug` | 0 | the diagnostic overlay |
| `Occupancy` | 1 | team-mates spread over different routes |
| `NavDistances` | 1 | the precomputed route tables (an exact A* heuristic) |
| `NavGenerate` | 1 | build navigation data for maps that have none |

`[BotClasslimits]` caps bots of each class per team: `Scout=2 Soldier=2
Sniper=1 Demoman=2 Medic=1 Engineer=2 Heavy=2 Spy=0 Pyro=2` by default, and the
server's own `[Classlimits]` still apply on top.

## Building

```
node tools/convert-policy.js        the C# server's checkpoints -> data/policy
node tools/navdata.js [--publish]   the reference gg2-navgen.exe -> build/data/navgen (+ stock maps' graphs -> data/nav)
node tools/navbench.js [map[:area]] time the GML generator against the exe, compare the files
node tools/build.js                 transpile, lint, install into a dev game
node tools/build.js --zip           and write dist/gg2-bots.zip
node tools/test-botc.js             transpiler tests
node tools/livecheck.js             drive a running gg2_session through maps
```

## Releasing

Lint and check locally (`node tools/build.js`, `node tools/livecheck.js`), then
push a tag:

```
git tag v1.0.0
git push origin v1.0.0
```

`.github/workflows/release.yml` runs the transpiler tests, builds
`dist/gg2-bots.zip` from the committed source and `data/`, and attaches it to
a GitHub release of that tag. It can also be run by hand from the Actions tab,
which builds the zip as a workflow artifact without releasing it.
