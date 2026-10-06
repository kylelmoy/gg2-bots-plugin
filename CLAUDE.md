# gg2-bots-plugin

gg2-server's bots (the scripted bot, the learned policy and the hybrid of the
two) as a local plugin for the original Game Maker 8 Gang Garrison 2. Only the
host needs it; clients are stock.

## Read before writing

- `docs/PORTING.md` - the contract: how plugin GML is written (no scripts; the
  transpiler and its rules), how C# names become GML names, the nav graph in
  memory, the order of a tick. Everything else assumes it.
- `D:/Code/gg2-agent/GML.md` - the GM8 dialect's traps. Every one of them has
  cost a day somewhere.
- `docs/NAVFILES.md` - the nav files and `gg2-navgen.exe`.
- The C# being ported: `D:/Code/gg2-server/src/GG2.Bots/`. It is the spec.

## Layout

| path | what |
|---|---|
| `src/bots.gml` | the bootstrap the game's plugin loader runs; plain GML, not transpiled |
| `src/fn/<module>/<name>.gml` | one function per file (see PORTING.md) |
| `src/hooks/<Object>/<event>.gml` | code appended to a game object's event |
| `src/constants/*.txt` | compile-time constants; `generated.txt` comes from gg2-server |
| `tools/build.js` | transpile, lint, assemble `dist/Plugins/`, install into the game |
| `tools/botc.js` | the transpiler; `tools/test-botc.js` tests it |
| `docs/departures/<module>.md` | where and why the GML differs from the C# |

## Build

```
node tools/build.js                 transpile, lint, install into D:/Code/Gang-Garrison-2/Source/build/Plugins
node tools/build.js --stub-missing  lint only, stubbing functions not written yet
node tools/build.js --zip           also write dist/gg2-bots.zip
node tools/test-botc.js             transpiler tests
```

## Running it live

`node tools/gg2.js gg2_session '{"action":"start","clients":1}'` starts a
dedicated GM8 server and a client from the game checkout (gg2-agent must be
beside this repo); the plugin is whatever was last installed. `gg2_evalx`,
`gg2_state`, `gg2_screenshot` read it back. One session at a time on this
machine. A plugin change needs a session restart - the plugin compiles when the
server starts.

## GM8 traps this repo has already paid for

- **`room_goto` ends the current event**: no later action in that event runs.
  GameServer's Create and Destroy both call it, so the bootstrap starts the
  layer from GameServer's End Step and notices the stop from AudioControl.
  Never append to an event that changes room.
- **Plugin functions are not scripts**: from `gg2_eval` call one as
  `event_perform_object(global.botF_<name>, ev_other, ev_user0)`, with its
  arguments in `global.botA0..`.
- **A dead bot is passed as `char == -1`** everywhere (PORTING.md); `noone`
  is not the same thing and reads as an unknown variable.

`node tools/livecheck.js` (with a `gg2_session` running) is the regression
check: every map of every mode, errors, movement, cost.

## Environment traps

- Shell heredocs in this environment collapse `\\` and turn `\r`/`\n` escapes
  into real control characters. Write any file containing backslashes with the
  Write tool, never `cat <<EOF` or an inline `python -c`/`node -e`.
- Commit messages: terse summary line, a body of at most two sentences.
