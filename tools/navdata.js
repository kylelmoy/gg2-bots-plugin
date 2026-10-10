#!/usr/bin/env node
//=============================================================================
// navdata.js - put the C# nav generator and its nav files for the shipped maps
// in build/. The plugin no longer ships the exe (its generator is GML); this
// is the reference tools/navbench.js times and compares the GML against.
//
//   node tools/navdata.js [--server <C# server worktree>] [--exe <gg2-navgen.exe>] [--publish]
//
// 1. --publish first runs `dotnet publish` for gg2-navgen in the C# server
//    worktree (default D:/Code/gg2-server-botsplugin, branch bots-plugin-navgen,
//    or GG2_SERVER_NAVGEN). Without it the last published exe is used.
// 2. Copies the exe (default <server>/src/GG2.NavGen/bin/publish/gg2-navgen.exe)
//    to build/data/navgen/gg2-navgen.exe.
// 3. Empties build/data/nav and runs `gg2-navgen --all --out build/data/nav`.
// 4. Replaces data/nav (committed) with the graphs (.txt) of that run: what the
//    zip ships. The distance tables (.dist) stay in build/data/nav, which
//    tools/build.js installs into a dev game only. docs/NAVFILES.md has the formats.
//=============================================================================
'use strict';

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const ROOT = path.resolve(__dirname, '..');
const DATA = path.join(ROOT, 'build', 'data');

const args = process.argv.slice(2);
function opt(name, fallback) {
  const i = args.indexOf(name);
  return i >= 0 && i + 1 < args.length ? args[i + 1] : fallback;
}

const SERVER = opt('--server', process.env.GG2_SERVER_NAVGEN || 'D:/Code/gg2-server-botsplugin');
const PROJECT = path.join(SERVER, 'src', 'GG2.NavGen');
const PUBLISHED = path.join(PROJECT, 'bin', 'publish');
const EXE = opt('--exe', path.join(PUBLISHED, 'gg2-navgen.exe'));

function run(cmd, cmdArgs, cwd) {
  const r = spawnSync(cmd, cmdArgs, { cwd, stdio: 'inherit' });
  if (r.error) throw r.error;
  if (r.status !== 0) {
    console.error(`navdata: ${cmd} ${cmdArgs.join(' ')} exited ${r.status}`);
    process.exit(1);
  }
}

if (args.includes('--publish')) {
  run('dotnet', ['publish', PROJECT, '-c', 'Release', '-r', 'win-x64', '-o', PUBLISHED], SERVER);
}

if (!fs.existsSync(EXE)) {
  console.error(`navdata: no ${EXE}; run with --publish, or see docs/NAVFILES.md, "Building the generator"`);
  process.exit(1);
}

const navgenDir = path.join(DATA, 'navgen');
const navDir = path.join(DATA, 'nav');
fs.mkdirSync(navgenDir, { recursive: true });
const exe = path.join(navgenDir, 'gg2-navgen.exe');
fs.copyFileSync(EXE, exe);

// Emptied first: a graph left over from an older map list or format must not ship.
fs.rmSync(navDir, { recursive: true, force: true });
fs.mkdirSync(navDir, { recursive: true });

const started = Date.now();
run(exe, ['--all', '--out', navDir], ROOT);

let bytes = 0;
const files = fs.readdirSync(navDir);
for (const f of files) bytes += fs.statSync(path.join(navDir, f)).size;
console.log(`navdata: ${files.length} files, ${(bytes / 1048576).toFixed(1)} MB in ${Date.now() - started} ms -> ${path.relative(ROOT, navDir)}`);
const shipDir = path.join(ROOT, 'data', 'nav');
fs.rmSync(shipDir, { recursive: true, force: true });
fs.mkdirSync(shipDir, { recursive: true });
const graphs = files.filter((f) => f.endsWith('.txt'));
for (const f of graphs) fs.copyFileSync(path.join(navDir, f), path.join(shipDir, f));
console.log(`navdata: ${graphs.length} graphs -> ${path.relative(ROOT, shipDir)}`);
console.log(`navdata: ${path.relative(ROOT, exe)} (${(fs.statSync(exe).size / 1048576).toFixed(1)} MB)`);
