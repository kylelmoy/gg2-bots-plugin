#!/usr/bin/env node
//=============================================================================
// build.js - transpile, lint, assemble and install the plugin.
//
//   node tools/build.js [--no-lint] [--no-install] [--game <build dir>] [--zip]
//   node tools/build.js --stub-missing     lint only, with every called-but-undefined
//                                          bot*/nav* function stubbed out
//
// 1. Every src/fn/**/<name>.gml is a function and every
//    src/hooks/<Object>/<event>.gml an event appended to a game object.
//    botc.js rewrites both (see its header for the rules) into build/code/.
// 2. build/code is linted with the agent tools' gml-lint.js against the game's own
//    tree. A compile error in code attached with object_event_add is a FATAL
//    error dialog the first time the event runs, so nothing is installed unless
//    this passes.
// 3. dist/Plugins/ is assembled: bots.gml (the bootstrap the game's loader
//    runs) and bots/ (the code, the manifest, the host menu tab, nav data and
//    policy weights). The nav generator is GML (src/fn/navgen); nothing
//    native ships.
// 4. dist/Plugins/ is copied over <game>/Plugins/. --zip also writes
//    dist/gg2-bots.zip for release.
//=============================================================================

'use strict';

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const { transpile, loadConstants, NAME_RE } = require('./botc.js');

const ROOT = path.resolve(__dirname, '..');
const SRC = path.join(ROOT, 'src');
const BUILD = path.join(ROOT, 'build');
const DIST = path.join(ROOT, 'dist');
const LINT = process.env.GML_LINT || 'D:/Code/gg2-agent/tools/gml-lint.js';
const DEFAULT_GAME = process.env.GG2_GAME || 'D:/Code/Gang-Garrison-2/Source/build';

// The nav graph keys of the maps a stock game ships, every area (what
// `gg2-navgen --all` writes); --zip refuses to build without all of them.
const STOCK_NAV_KEYS = [
  'arena_lumberyard_a1', 'arena_montane_a1', 'cp_dirtbowl_a1', 'cp_dirtbowl_a2', 'cp_dirtbowl_a3',
  'cp_egypt_a1', 'ctf_2dfort_a1', 'ctf_avanti_a1', 'ctf_classicwell_a1', 'ctf_conflict_a1',
  'ctf_eiger_a1', 'ctf_oldfort_a1', 'ctf_orange_a1', 'ctf_truefort_a1', 'ctf_waterway_a1',
  'dkoth_atalia_a1', 'dkoth_sixties_a1', 'gen_destroy_a1', 'gg_debug_a1', 'koth_corinth_a1',
  'koth_gallery_a1', 'koth_harvest_a1', 'koth_valley_a1', 'tdm_mantic_a1',
];

// File name -> [event type constant, event number]
const EVENTS = {
  create: ['ev_create', 0],
  destroy: ['ev_destroy', 0],
  begin_step: ['ev_step', 'ev_step_begin'],
  step: ['ev_step', 'ev_step_normal'],
  end_step: ['ev_step', 'ev_step_end'],
  draw: ['ev_draw', 0],
  room_start: ['ev_other', 'ev_room_start'],
  room_end: ['ev_other', 'ev_room_end'],
  game_end: ['ev_other', 'ev_game_end'],
};
for (let i = 0; i < 12; i++) EVENTS[`alarm${i}`] = ['ev_alarm', i];
for (let i = 0; i < 16; i++) EVENTS[`user${i}`] = ['ev_other', `ev_user${i}`];

function walk(dir) {
  if (!fs.existsSync(dir)) return [];
  const out = [];
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, e.name);
    if (e.isDirectory()) out.push(...walk(full));
    else out.push(full);
  }
  return out.sort();
}

function rel(p) {
  return path.relative(ROOT, p).split(path.sep).join('/');
}

function rmrf(p) {
  fs.rmSync(p, { recursive: true, force: true });
}

function copyDir(from, to) {
  fs.mkdirSync(to, { recursive: true });
  for (const e of fs.readdirSync(from, { withFileTypes: true })) {
    const a = path.join(from, e.name);
    const b = path.join(to, e.name);
    if (e.isDirectory()) copyDir(a, b);
    else fs.copyFileSync(a, b);
  }
}

// Collect and transpile. Returns { manifest, errors }.
// Every bot*/nav* name called somewhere in `files` but defined nowhere.
function missingCalls(files, funcs) {
  const { tokenize } = require('./botc.js');
  const missing = new Map();
  for (const f of files) {
    const toks = tokenize(fs.readFileSync(f, 'utf8'), rel(f)).filter((t) => t.type !== 'ws' && t.type !== 'comment');
    for (let i = 0; i + 1 < toks.length; i++) {
      const t = toks[i];
      if (t.type === 'ident' && NAME_RE.test(t.text) && toks[i + 1].text === '(' && !funcs.has(t.text)
          && !(i > 0 && toks[i - 1].text === '.')) {
        if (!missing.has(t.text)) missing.set(t.text, `${rel(f)}:${t.line}`);
      }
    }
  }
  return missing;
}

function compile({ stubMissing = false } = {}) {
  const errors = [];
  const fnFiles = walk(path.join(SRC, 'fn')).filter((f) => f.endsWith('.gml'));
  const hookFiles = walk(path.join(SRC, 'hooks')).filter((f) => f.endsWith('.gml'));

  const funcs = new Map();
  for (const f of fnFiles) {
    const name = path.basename(f, '.gml');
    if (!NAME_RE.test(name)) errors.push(`${rel(f)}: function name '${name}' must start with bot or nav followed by a capital`);
    if (funcs.has(name)) errors.push(`${rel(f)}: function '${name}' is also defined in ${rel(funcs.get(name))}`);
    funcs.set(name, f);
  }

  const hooks = [];
  for (const f of hookFiles) {
    const object = path.basename(path.dirname(f));
    const event = path.basename(f, '.gml');
    if (!EVENTS[event]) {
      errors.push(`${rel(f)}: unknown event '${event}' (known: ${Object.keys(EVENTS).join(', ')})`);
      continue;
    }
    hooks.push({ object, event, file: f });
  }

  const constants = new Map();
  for (const f of walk(path.join(SRC, 'constants')).filter((x) => x.endsWith('.txt'))) {
    errors.push(...loadConstants(fs.readFileSync(f, 'utf8'), rel(f), constants));
  }
  for (const name of constants.keys()) {
    if (funcs.has(name)) errors.push(`constant ${name} has the name of a function`);
  }

  rmrf(path.join(BUILD, 'code'));
  fs.mkdirSync(path.join(BUILD, 'code', 'fn'), { recursive: true });
  fs.mkdirSync(path.join(BUILD, 'code', 'hooks'), { recursive: true });

  const lines = [];
  const names = new Set(funcs.keys());
  // --stub-missing: a function another part of the port has not written yet
  // becomes an empty one, so the rest can be linted. Never installed.
  let stubs = [];
  if (stubMissing) {
    const missing = missingCalls([...fnFiles, ...hookFiles], funcs);
    stubs = [...missing.keys()].sort();
    for (const name of stubs) {
      names.add(name);
      fs.writeFileSync(path.join(BUILD, 'code', 'fn', `${name}.gml`), `// STUB for lint: first called at ${missing.get(name)}\n`);
    }
  }
  const arity = new Map();
  const allCalls = [];
  for (const [name, f] of funcs) {
    const src = fs.readFileSync(f, 'utf8');
    const r = transpile(src, rel(f), names, { isFunction: true, constants });
    if (r.errors) { errors.push(...r.errors); continue; }
    arity.set(name, r.arity);
    for (const c of r.calls) allCalls.push({ ...c, file: rel(f) });
    fs.writeFileSync(path.join(BUILD, 'code', 'fn', `${name}.gml`), r.code);
    lines.push(`fn ${name} code/fn/${name}.gml`);
  }
  for (const h of hooks) {
    const src = fs.readFileSync(h.file, 'utf8');
    const r = transpile(src, rel(h.file), names, { isFunction: false, constants });
    if (r.errors) { errors.push(...r.errors); continue; }
    for (const c of r.calls) allCalls.push({ ...c, file: rel(h.file) });
    const out = `${h.object}__${h.event}.gml`;
    fs.writeFileSync(path.join(BUILD, 'code', 'hooks', out), r.code);
    const [type, numb] = EVENTS[h.event];
    lines.push(`hook ${h.object} ${type} ${numb} code/hooks/${out}`);
  }
  // Arity: a call passing fewer arguments than the function reads leaves it
  // reading whatever the last call left in global.botA<n>, silently. More is a
  // sign of disagreement but is harmless (trailing arguments the callee ignores).
  for (const c of allCalls) {
    if (!arity.has(c.name)) continue;
    const want = arity.get(c.name);
    if (c.args < want) errors.push(`${c.file}:${c.line}: ${c.name} takes ${want} argument(s), called with ${c.args}`);
  }
  // Functions first: a hook may call any of them the moment it is attached.
  lines.sort((a, b) => (a.startsWith('fn') === b.startsWith('fn') ? 0 : a.startsWith('fn') ? -1 : 1));
  fs.writeFileSync(path.join(BUILD, 'code', 'manifest.txt'), lines.join('\r\n') + '\r\n');
  return { errors, functions: funcs.size, hooks: hooks.length, constants: constants.size, stubs };
}

function lint() {
  const r = spawnSync(process.execPath, [LINT, path.join(BUILD, 'code'), path.join(SRC, 'bots.gml'), path.join(SRC, 'menu.gml')], { encoding: 'utf8' });
  const out = (r.stdout || '') + (r.stderr || '');
  // Map build/code paths back to their sources for readable errors.
  const mapped = out.replace(/build[\\/]code[\\/]fn[\\/]([A-Za-z0-9_]+)\.gml/g, (m, name) => {
    const hit = walk(path.join(SRC, 'fn')).find((f) => path.basename(f, '.gml') === name);
    return hit ? rel(hit) : m;
  });
  process.stdout.write(mapped);
  return r.status === 0;
}

function assemble() {
  const out = path.join(DIST, 'Plugins');
  rmrf(out);
  fs.mkdirSync(path.join(out, 'bots'), { recursive: true });
  fs.copyFileSync(path.join(SRC, 'bots.gml'), path.join(out, 'bots.gml'));
  fs.copyFileSync(path.join(SRC, 'menu.gml'), path.join(out, 'bots', 'menu.gml'));
  copyDir(path.join(BUILD, 'code'), path.join(out, 'bots', 'code'));
  // Static data shipped beside the code: policy weights and nav graphs, each
  // produced by its own tool into build/data/.
  for (const d of ['policy', 'nav']) {
    const from = path.join(BUILD, 'data', d);
    if (fs.existsSync(from)) copyDir(from, path.join(out, 'bots', d));
  }
  const ini = path.join(SRC, 'bots.ini');
  if (fs.existsSync(ini)) fs.copyFileSync(ini, path.join(out, 'bots', 'bots.ini.example'));
  return out;
}

function install(game, out) {
  if (!fs.existsSync(game)) {
    console.log(`build: ${game} not found, not installed`);
    return;
  }
  const dest = path.join(game, 'Plugins');
  // Replace the code wholesale so a deleted source file does not linger, but
  // leave nav/ alone apart from adding to it: it also holds graphs the
  // generator made for custom maps on this machine.
  rmrf(path.join(dest, 'bots', 'code'));
  // Every .txt in policy/ loads as a network, so a renamed one must not linger.
  rmrf(path.join(dest, 'bots', 'policy'));
  // gg2-navgen.exe shipped here until the generator was ported to GML.
  rmrf(path.join(dest, 'bots', 'navgen'));
  copyDir(out, dest);
  console.log(`build: installed to ${dest}`);
}

function main() {
  const args = process.argv.slice(2);
  const flag = (f) => args.includes(f);
  const gi = args.indexOf('--game');
  const game = gi >= 0 ? args[gi + 1] : DEFAULT_GAME;

  const stubMissing = flag('--stub-missing');
  const c = compile({ stubMissing });
  if (c.errors.length) {
    for (const e of c.errors) console.error(e);
    console.error(`build: ${c.errors.length} error(s), nothing built`);
    process.exit(1);
  }
  console.log(`build: ${c.functions} functions, ${c.hooks} hooks, ${c.constants} constants`);
  if (c.stubs.length) console.log(`build: stubbed ${c.stubs.length} missing function(s): ${c.stubs.join(', ')}`);
  if (!flag('--no-lint') && !lint()) {
    console.error('build: lint failed, nothing installed');
    process.exit(1);
  }
  if (stubMissing) {
    console.log('build: --stub-missing builds are for linting only; nothing assembled or installed');
    return;
  }
  const out = assemble();
  if (flag('--zip')) {
    const { makeZip } = require('./zip.js');
    // The stock maps' graphs ship (1.1 MB deflated), so bots walk on them from
    // the first round. Their distance tables do not (32 MB deflated): the GML
    // generator derives a missing .dist in the background the first time a
    // map is played (docs/NAVFILES.md).
    const navDir = path.join(out, 'bots', 'nav');
    const missing = STOCK_NAV_KEYS.filter((k) => !fs.existsSync(path.join(navDir, `${k}.txt`)));
    if (missing.length) {
      console.error(`build: no nav graph for ${missing.join(', ')}; run tools/navdata.js first`);
      process.exit(1);
    }
    const shipped = (f) => {
      const p = f.split(path.sep).join('/');
      if (!p.includes('/bots/nav/')) return true;
      return STOCK_NAV_KEYS.includes(path.basename(p, '.txt')) && p.endsWith('.txt');
    };
    const entries = walk(out).filter(shipped).map((f) => ({
      name: path.relative(path.dirname(out), f).split(path.sep).join('/'),
      data: fs.readFileSync(f),
    }));
    fs.writeFileSync(path.join(DIST, 'gg2-bots.zip'), makeZip(entries));
    console.log(`build: dist/gg2-bots.zip, ${entries.length} files`);
  }
  if (!flag('--no-install')) install(game, out);
}

if (require.main === module) main();
module.exports = { compile };
