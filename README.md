# gg2-bots

Bots for the original Gang Garrison 2 (the Game Maker 8 game), as a plugin.

These are the bots of a C# Gang Garrison 2 server - the scripted bot and the
learned policy that takes the wheel in a fight - re-expressed in GML so that
anyone who hosts the original game can play with them. Only the host installs
anything: bots are ordinary players to everybody who connects, and a stock
client needs no plugin, no download and no restart.

## Install

1. Extract `gg2-bots.zip` into the folder that holds `Gang Garrison 2.exe`.
   It adds `Plugins/bots.gml` and `Plugins/bots/`.
2. Host a game, from the menu or with `-dedicated`. Bots join once at least one
   person is in the game (on a listen server, that is you).

Nothing else is required. The zip carries `gg2-navgen.exe`, which builds a
map's navigation data the first time the map is played (a fraction of a
second; bots fight without walking until it is ready). It is a Windows
program, like the game.

## What they do

Everything those bots do, in every mode the game has (CTF, control
points, attack/defend, king of the hill, dual KOTH, generator, arena, team
deathmatch) and on custom maps:

- walk, fall, drop through platforms, jump, double jump (scout) and rocket
  jump (soldier) along a navigation graph built from the map;
- take the objective by role - attackers push, defenders hold, a medic
  follows a patient, an engineer covers a chokepoint, a sniper takes a
  sightline, a spy flanks out of sight;
- pick targets the way a sentry does, lead and arc their shots, dodge rockets,
  airblast, detonate stickies, back off from point-blank range;
- and, for scout, soldier, demoman, heavy and pyro within 150 px of a person,
  hand the keys to a trained policy network, the hybrid that beat
  the all-scripted bot there.

Difficulty 1-5 sets reaction time, aim settling, tracking and error, as in
the C# server.

## Settings

All in the game's own `gg2.ini`, under the same keys the C# server reads, so one
config section serves either server. Every key is optional.

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
| `Occupancy` | 1 | team-mates spread over different routes |
| `NavDistances` | 1 | the precomputed route tables (an exact A* heuristic) |
| `NavGenerate` | 1 | build navigation data for maps that have none |

`[BotClasslimits]` caps bots of each class per team: `Scout=2 Soldier=2
Sniper=1 Demoman=2 Medic=1 Engineer=2 Heavy=2 Spy=0 Pyro=2` by default, and the
server's own `[Classlimits]` still apply on top.

A bot holds a real player slot, so the plugin always leaves one free: a person
arriving at a full server is never refused because of bots, and a bot leaves
to make room for the next one.

## Cost

Measured on the dev machine with 12 bots on a dedicated server at 30 fps:
3-6 ms of a 33 ms frame on average across ten maps of every mode, and under 1%
of frames over 20 ms. The game held 30 fps throughout. The policy network
runs on GM8's native grid operations and costs 1.5-4 ms per decision, which
is why `Arbiter` budgets it per tick. The server's machine matters more than
anything here: GML is interpreted.

## How it works

In short:

- **A bot is a real client of its own server.** It connects over loopback and
  joins through the ordinary handshake, exactly as the game connects the
  host's own player, so nothing in the game needed patching and every command
  a bot gives (team, class, zoom, build, eat, drop) is the one a person's
  client sends. Its keys and aim are written onto its character at the point
  a person's input is read, so clients see bots the way they see anyone.
- **A plugin cannot define scripts**, so the source is compiled by
  `tools/botc.js`: each function becomes an event of its own object, compiled
  once when hosting starts and called with `event_perform_object`.
- **The C# is the specification.** Each module is a port of the C# server's
  `GG2.Bots`, read against the game's own objects.
- **Navigation data comes from the C# server's own generator**,
  `gg2-navgen.exe`, built from a checkout of that server.

## Building

```
node tools/convert-policy.js        the C# server's checkpoints -> build/data/policy
node tools/navdata.js [--publish]   gg2-navgen.exe -> build/data/navgen (+ every stock map's nav data)
node tools/build.js                 transpile, lint, install into a dev game
node tools/build.js --zip           and write dist/gg2-bots.zip
node tools/test-botc.js             transpiler tests
node tools/livecheck.js             drive a running gg2_session through maps
```

Needs Node 18+, Game Maker 8 and a GML linter (`GML_LINT`), and the C#
server's source (for the checkpoints and the generator).
