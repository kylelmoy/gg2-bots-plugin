#!/usr/bin/env node
//=============================================================================
// navdata.js - put the nav generator and the shipped maps' nav files in build/.
//
//   node tools/navdata.js [--server <gg2-server worktree>] [--exe <gg2-navgen.exe>] [--publish]
//
// 1. --publish first runs `dotnet publish` for gg2-navgen in the gg2-server
//    worktree (default D:/Code/gg2-server-botsplugin, branch bots-plugin-navgen,
//    or GG2_SERVER_NAVGEN). Without it the last published exe is used.
// 2. Copies the exe (default <server>/src/GG2.NavGen/bin/publish/gg2-navgen.exe)
//    to build/data/navgen/gg2-navgen.exe.
// 3. Empties build/data/nav and runs `gg2-navgen --all --out build/data/nav`.
//
// tools/build.js copies build/data/{navgen,nav,policy} into the plugin. Nothing
// here is committed: build/ is gitignored. docs/NAVFILES.md has the formats.
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
console.log(`navdata: ${path.relative(ROOT, exe)} (${(fs.statSync(exe).size / 1048576).toFixed(1)} MB)`);
