#!/usr/bin/env node
//=============================================================================
// build.js - transpile, lint, assemble and install the plugin.
//
//   node tools/build.js [--no-lint] [--no-install] [--game <build dir>] [--zip]
//
// 1. Every src/fn/**/<name>.gml is a function and every
//    src/hooks/<Object>/<event>.gml an event appended to a game object.
//    botc.js rewrites both (see its header for the rules) into build/code/.
// 2. build/code is linted with gg2-agent's gml-lint.js against the game's own
//    tree. A compile error in code attached with object_event_add is a FATAL
//    error dialog the first time the event runs, so nothing is installed unless
//    this passes.
// 3. dist/Plugins/ is assembled: bots.gml (the bootstrap the game's loader
//    runs) and bots/ (the code, the manifest, nav data, policy weights and the
//    nav generator).
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
function compile() {
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
  for (const [name, f] of funcs) {
    const src = fs.readFileSync(f, 'utf8');
    const r = transpile(src, rel(f), names, { isFunction: true, constants });
    if (r.errors) { errors.push(...r.errors); continue; }
    fs.writeFileSync(path.join(BUILD, 'code', 'fn', `${name}.gml`), r.code);
    lines.push(`fn ${name} code/fn/${name}.gml`);
  }
  for (const h of hooks) {
    const src = fs.readFileSync(h.file, 'utf8');
    const r = transpile(src, rel(h.file), names, { isFunction: false, constants });
    if (r.errors) { errors.push(...r.errors); continue; }
    const out = `${h.object}__${h.event}.gml`;
    fs.writeFileSync(path.join(BUILD, 'code', 'hooks', out), r.code);
    const [type, numb] = EVENTS[h.event];
    lines.push(`hook ${h.object} ${type} ${numb} code/hooks/${out}`);
  }
  // Functions first: a hook may call any of them the moment it is attached.
  lines.sort((a, b) => (a.startsWith('fn') === b.startsWith('fn') ? 0 : a.startsWith('fn') ? -1 : 1));
  fs.writeFileSync(path.join(BUILD, 'code', 'manifest.txt'), lines.join('\r\n') + '\r\n');
  return { errors, functions: funcs.size, hooks: hooks.length, constants: constants.size };
}

function lint() {
  const r = spawnSync(process.execPath, [LINT, path.join(BUILD, 'code'), path.join(SRC, 'bots.gml')], { encoding: 'utf8' });
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
  copyDir(path.join(BUILD, 'code'), path.join(out, 'bots', 'code'));
  // Static data shipped beside the code: policy weights, nav graphs, the
  // generator. Each is produced by its own tool into build/ or data/.
  for (const d of ['policy', 'nav', 'navgen']) {
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
  copyDir(out, dest);
  console.log(`build: installed to ${dest}`);
}

function main() {
  const args = process.argv.slice(2);
  const flag = (f) => args.includes(f);
  const gi = args.indexOf('--game');
  const game = gi >= 0 ? args[gi + 1] : DEFAULT_GAME;

  const c = compile();
  if (c.errors.length) {
    for (const e of c.errors) console.error(e);
    console.error(`build: ${c.errors.length} error(s), nothing built`);
    process.exit(1);
  }
  console.log(`build: ${c.functions} functions, ${c.hooks} hooks, ${c.constants} constants`);
  if (!flag('--no-lint') && !lint()) {
    console.error('build: lint failed, nothing installed');
    process.exit(1);
  }
  const out = assemble();
  if (flag('--zip')) {
    const { makeZip } = require('./zip.js');
    const entries = walk(out).map((f) => ({
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
