#!/usr/bin/env node
//=============================================================================
// navbench.js - time the GML nav generator against gg2-navgen.exe and check
// that they produce the same files.
//
//   node tools/navbench.js [--no-dist] [--exe <gg2-navgen.exe>] [map[:area] ...]
//
// Expects `gg2_session start` already running with the plugin installed (a
// server is enough; no bots are needed). For each map it changes the server to
// it, freezes the map check (global.botNavAlive), generates
// nav/gmltest_<key>.txt and .dist with navGenStart/navGenStep stepped back to
// back, then runs the exe on the same map into a temporary directory, and
// compares the two with navcompare.js. The server is left with the map check
// frozen: restart the session afterwards.
//=============================================================================
'use strict';
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');
const mcp = require('D:/Code/gg2-agent/tools/gg2-mcp-server.js');

const ROOT = path.resolve(__dirname, '..');
const GAME = process.env.GG2_GAME || 'D:/Code/Gang-Garrison-2/Source/build';
const NAV = path.join(GAME, 'Plugins', 'bots', 'nav');
const STAGES = ['mask', 'clearance', 'nodes', 'walk/fall/drop', 'jump', 'doublejump', 'rocketjump', 'write'];

function text(r) {
  if (typeof r === 'string') return r;
  const parts = Array.isArray(r) ? r : (r && r.content) || [];
  return parts.filter((p) => p.type === 'text').map((p) => p.text).join('\n');
}
async function call(tool, args) {
  const r = await mcp.callTool(tool, { instance: 'server', ...args });
  if (r && r.isError) throw new Error(text(r));
  return text(r);
}
const evalx = (expr) => call('gg2_evalx', { expr });
const evalg = (code) => call('gg2_eval', { code });
const sleep = (ms) => new Promise((res) => setTimeout(res, ms));
const fn = (name, ...args) =>
  args.map((a, i) => `global.botA${i} = ${typeof a === 'string' ? JSON.stringify(a) : a};`).join(' ') +
  ` event_perform_object(global.botF_${name}, ev_other, ev_user0);`;

async function gotoMap(map, area) {
  await evalg(`global.botNavAlive = true; global.nextMap = "${map}"; global.currentMapArea = ${area}; GameServer.impendingMapChange = 1;`);
  for (let i = 0; i < 120; i++) {
    await sleep(500);
    const r = await evalx(`global.currentMap + "|" + string(global.currentMapArea) + "|" + string(instance_number(CustomMapO)) + "|" + global.botNavKey`);
    const [cur, a, inst, key] = r.split('|');
    if (cur === map && +a === area && +inst > 0 && key.startsWith(map)) return key;
  }
  throw new Error(`server never reached ${map} area ${area}`);
}

async function stepUntil(stages) {
  for (;;) {
    await evalg(fn('navGenStep', 3000));
    const s = +(await evalx('global.navGenStage'));
    if (stages.includes(s)) return s;
  }
}

function runExe(exe, map, area) {
  const out = fs.mkdtempSync(path.join(os.tmpdir(), 'navbench-'));
  const t0 = process.hrtime.bigint();
  const r = spawnSync(exe, ['--map', map, '--area', String(area), '--key', 'exe', '--out', out], { encoding: 'utf8' });
  const ms = Number(process.hrtime.bigint() - t0) / 1e6;
  if (r.status !== 0) throw new Error(`exe failed: ${r.stderr}`);
  return { ms, txt: path.join(out, 'exe.txt'), dist: path.join(out, 'exe.dist'), dir: out };
}

async function main() {
  const args = process.argv.slice(2);
  const noDist = args.includes('--no-dist');
  const ei = args.indexOf('--exe');
  const exe = ei >= 0 ? args[ei + 1] : path.join(ROOT, 'build', 'data', 'navgen', 'gg2-navgen.exe');
  const maps = args.filter((a, i) => !a.startsWith('--') && (ei < 0 || i !== ei + 1));
  const rows = [];

  for (const spec of maps.length ? maps : ['ctf_truefort']) {
    const [map, areaText] = spec.split(':');
    const area = +(areaText || 1);
    const key = await gotoMap(map, area);
    const testKey = `gmltest_${key}`;
    // Let the map check settle on the new room, then freeze it.
    await sleep(1500);
    await evalg(`global.botNavAlive = false; ${fn('navGenFree')}`);

    await evalg(`${fn('navGenStart', testKey, 0)} global.benchOk = global.botRet;`);
    if (+(await evalx('global.benchOk')) !== 1) throw new Error(`navGenStart refused ${map}`);
    const end = await stepUntil([8, 11]);
    if (end !== 8) throw new Error(`graph generation failed on ${map}`);
    // Stage entry times (current_time) for stages 0..8, 8 being "graph done".
    const stageAt = (await evalx(
      [0, 1, 2, 3, 4, 5, 6, 7, 8].map((s) => `string(global.navGenStageAt[${s}])`).join(' + "|" + ')
    )).split('|').map(Number);
    const stageMs = stageAt.slice(0, 8).map((t, i) => stageAt[i + 1] - t);
    const graphMs = stageAt[8] - stageAt[0];

    let distMs = null;
    if (!noDist) {
      // Install the generated graph as the live one, then derive its tables.
      await evalg(
        `${fn('navGraphFree')} ${fn('navGraphTryLoad', path.join(NAV, testKey + '.txt').split(path.sep).join('/'))} ` +
        `global.botNavReady = global.botRet; if (global.botNavReady) { ${fn('navGenDistSetup')} }`
      );
      if (+(await evalx('global.botNavReady')) !== 1) throw new Error(`generated graph for ${map} did not load`);
      const before = +(await evalx('global.navGenMs'));
      await stepUntil([11]);
      distMs = +(await evalx('global.navGenMs')) - before;
    }
    await evalg(fn('navGenFree'));

    const x = runExe(exe, map, area);
    const cmp = spawnSync(process.execPath, [
      path.join(__dirname, 'navcompare.js'), path.join(NAV, testKey + '.txt'), x.txt, '--quiet',
      ...(noDist ? [] : ['--dist', path.join(NAV, testKey + '.dist'), x.dist]),
    ], { encoding: 'utf8' });
    fs.rmSync(x.dir, { recursive: true, force: true });

    console.log(`\n== ${key}`);
    console.log(`GML graph ${graphMs} ms (${STAGES.map((s, i) => `${s} ${stageMs[i]}`).join(', ')})` +
      (distMs === null ? '' : `, tables ${distMs} ms`) + `; exe ${x.ms.toFixed(0)} ms end to end`);
    console.log(cmp.stdout.trim());
    rows.push({ key, graphMs, distMs, exeMs: x.ms, same: cmp.status === 0 });
  }

  console.log('\nmap                        GML graph   GML tables   exe (both)   same');
  for (const r of rows) {
    console.log(`${r.key.padEnd(26)} ${String(r.graphMs).padStart(9)}   ${String(r.distMs ?? '-').padStart(10)}   ` +
      `${r.exeMs.toFixed(0).padStart(10)}   ${r.same ? 'yes' : 'NO'}`);
  }
  process.exit(rows.every((r) => r.same) ? 0 : 1);
}

if (require.main === module) {
  main().catch((e) => {
    console.error(e.message);
    process.exit(1);
  });
}
