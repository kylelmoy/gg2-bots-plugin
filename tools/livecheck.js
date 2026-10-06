#!/usr/bin/env node
//=============================================================================
// livecheck.js - drive a running gg2_session server through maps and report
// what its bots did.
//
//   node tools/livecheck.js [--seconds 60] [map ...]
//
// Expects `gg2_session start` already running (server + at least one client,
// so there is a human and the bots join) with the plugin installed. For each
// map: change to it, wait, then sample every few seconds - how far each bot
// moved, deaths, captures, policy ticks, the bot layer's per-frame cost - and
// read the launcher log for GML errors raised in the meantime. Exit code 1 if
// any map raised an error or had a bot that never moved.
//=============================================================================
'use strict';
const fs = require('fs');
const mcp = require('D:/Code/gg2-agent/tools/gg2-mcp-server.js');

const LOG = 'D:/Code/Gang-Garrison-2/Source/build/agent_launcher_17777.log';
const DEFAULT_MAPS = [
  'ctf_truefort', 'koth_valley', 'cp_dirtbowl', 'gen_destroy', 'dkoth_atalia',
  'arena_montane', 'ctf_2dfort', 'koth_harvest', 'tdm_mantic', 'cp_egypt',
];

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
const errorLines = () => (fs.existsSync(LOG) ? fs.readFileSync(LOG, 'utf8').split('\n').filter((l) => / E\| /.test(l)) : []);

const SAMPLE = `
var s; s = "";
with (Player) if (botIsBot)
{
    s += string(id) + ":" + string(class) + ":" + string(team) + ":";
    if (object != -1) s += string(round(object.x)) + ":" + string(round(object.y)); else s += "-:-";
    s += ":" + string(stats[DEATHS]) + ":" + string(botHybridMicroTicks) + ":" + string(botPathStuckFires) + ":" + string(botPathBlacklistFires) + ";";
}
global.botLiveSample = s + "|" + string(global.redCaps) + "|" + string(global.blueCaps)
    + "|" + string(global.botCostSum / max(1, global.botCostTicks)) + "|" + string(global.botCostMax)
    + "|" + string(global.botNavReady) + "|" + global.currentMap;
`;

async function sample() {
  let raw = '';
  for (let tries = 0; tries < 10; tries++) {
    try {
      await evalg(SAMPLE);
      raw = await evalx('global.botLiveSample');
    } catch (e) {
      raw = '';
    }
    if (raw.split('|').length >= 7) break;
    await sleep(1000);
  }
  const [bots, red, blue, cost, max, ready, map] = raw.split('|');
  const list = bots.split(';').filter(Boolean).map((b) => {
    const [id, cls, team, x, y, deaths, micro, stuck, black] = b.split(':');
    return { id, cls: +cls, team: +team, x: x === '-' ? null : +x, y: y === '-' ? null : +y, deaths: +deaths, micro: +micro, stuck: +stuck, black: +black };
  });
  return { list, red: +red, blue: +blue, cost: +cost, max: +max, ready: ready === '1', map };
}

async function main() {
  const args = process.argv.slice(2);
  const si = args.indexOf('--seconds');
  const seconds = si >= 0 ? +args[si + 1] : 60;
  const maps = args.filter((a, i) => !a.startsWith('--') && i !== si + 1);
  let failed = false;
  for (const map of maps.length ? maps : DEFAULT_MAPS) {
    const errsBefore = errorLines().length;
    await evalg(`global.nextMap = "${map}"; global.currentMapArea = 1; GameServer.impendingMapChange = 1; event_perform_object(global.botF_botStatsReset, ev_other, ev_user0);`);
    await sleep(6000);
    await evalg('event_perform_object(global.botF_botStatsReset, ev_other, ev_user0);');
    const moved = new Map();
    const last = new Map();
    let s;
    const t0 = Date.now();
    while (Date.now() - t0 < seconds * 1000) {
      s = await sample();
      for (const b of s.list) {
        if (b.x === null) continue;
        const p = last.get(b.id);
        if (p) moved.set(b.id, (moved.get(b.id) || 0) + Math.hypot(b.x - p.x, b.y - p.y));
        last.set(b.id, b);
      }
      await sleep(3000);
    }
    s = await sample();
    const errs = errorLines().slice(errsBefore);
    const still = s.list.filter((b) => (moved.get(b.id) || 0) < 50);
    const micro = s.list.reduce((a, b) => a + b.micro, 0);
    const deaths = s.list.reduce((a, b) => a + b.deaths, 0);
    const stuck = s.list.reduce((a, b) => a + b.stuck, 0);
    const black = s.list.reduce((a, b) => a + b.black, 0);
    const ok = errs.length === 0 && still.length === 0 && s.ready;
    if (!ok) failed = true;
    console.log(`${ok ? 'ok  ' : 'FAIL'} ${s.map.padEnd(16)} bots ${s.list.length} nav ${s.ready ? 'yes' : 'NO '} ` +
      `caps R${s.red} B${s.blue} deaths ${deaths} policyTicks ${micro} cost ${s.cost.toFixed(2)}ms max ${s.max}ms ` +
      `still ${still.length} stuck ${stuck} blacklisted ${black} errors ${errs.length}`);
    if (errs.length) console.log('     ' + [...new Set(errs.map((l) => l.replace(/^\S+\s+E\|\s*/, '')))].slice(0, 8).join('\n     '));
  }
  if (mcp.disconnectAll) mcp.disconnectAll();
  process.exit(failed ? 1 : 0);
}

main().catch((e) => { console.error(e.stack || e); process.exit(2); });
