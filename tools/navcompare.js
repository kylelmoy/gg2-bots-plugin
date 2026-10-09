#!/usr/bin/env node
//=============================================================================
// navcompare.js - compare two nav graph files (and optionally their distance
// tables): the GML generator's against gg2-navgen's.
//
//   node tools/navcompare.js <a.txt> <b.txt> [--dist <a.dist> <b.dist>] [--quiet]
//
// Nodes must match exactly, in order. Edges are compared as rows keyed by
// (from, to, type, takeoff): which ones only one side has, and the largest
// difference in the float fields (bucket, ticks, cost) of the shared ones.
// Byte equality of the whole file is reported too. Distance tables: header,
// then per table how many costs and next hops differ, and by how much.
// Exit 0 when the graphs are the same graph (same nodes, same edge rows,
// float fields within 1e-9).
//=============================================================================
'use strict';
const fs = require('fs');

function readGrid(hex) {
  const b = Buffer.from(hex.trim(), 'hex');
  const magic = b.readUInt32LE(0);
  if (magic !== 601) throw new Error(`grid magic ${magic}, not 601`);
  const w = b.readUInt32LE(4);
  const h = b.readUInt32LE(8);
  const cells = new Float64Array(w * h);
  let at = 12;
  for (let x = 0; x < w; x++) {
    for (let y = 0; y < h; y++) {
      const type = b.readUInt32LE(at);
      if (type !== 0) throw new Error(`cell ${x},${y} is type ${type}, not a real`);
      cells[y * w + x] = b.readDoubleLE(at + 4);
      at += 16;
    }
  }
  return { w, h, at: (x, y) => cells[y * w + x] };
}

function readGraph(file) {
  const text = fs.readFileSync(file, 'latin1');
  const lines = text.split(/\r?\n/);
  const [mw, mh, n, m] = lines[1].trim().split(/\s+/).map(Number);
  const nodes = readGrid(lines[2]);
  const edges = m > 0 ? readGrid(lines[3]) : null;
  return { text, version: lines[0].trim(), mw, mh, n, m, nodes, edges };
}

function compareGraphs(aFile, bFile, quiet) {
  const a = readGraph(aFile);
  const b = readGraph(bFile);
  const out = [];
  let same = true;
  out.push(`bytes ${a.text === b.text ? 'IDENTICAL' : 'differ'} (${a.text.length} vs ${b.text.length})`);
  if (a.version !== b.version || a.mw !== b.mw || a.mh !== b.mh) {
    out.push(`header differs: ${a.version} ${a.mw}x${a.mh} vs ${b.version} ${b.mw}x${b.mh}`);
    same = false;
  }
  out.push(`nodes ${a.n} vs ${b.n}, edges ${a.m} vs ${b.m}`);
  let nodeDiffs = 0;
  for (let i = 0; i < Math.min(a.n, b.n); i++) {
    for (let f = 0; f < 6; f++) {
      if (a.nodes.at(f, i) !== b.nodes.at(f, i)) {
        if (nodeDiffs < 5) {
          const row = (g) => [0, 1, 2, 3, 4, 5].map((k) => g.at(k, i)).join(',');
          out.push(`  node ${i}: [${row(a.nodes)}] vs [${row(b.nodes)}]`);
        }
        nodeDiffs++;
        break;
      }
    }
  }
  if (a.n !== b.n || nodeDiffs) {
    same = false;
    out.push(`  ${nodeDiffs} node rows differ`);
  }
  const rows = (g) => {
    const map = new Map();
    for (let e = 0; e < g.m; e++) {
      const r = [];
      for (let f = 0; f < 9; f++) r.push(g.edges.at(f, e));
      const key = `${r[0]}>${r[1]} t${r[2]} @${r[7]}`;
      if (!map.has(key)) map.set(key, []);
      map.get(key).push({ r, e });
    }
    return map;
  };
  const ea = rows(a);
  const eb = rows(b);
  const onlyA = [];
  const onlyB = [];
  let maxDiff = 0;
  let worst = '';
  let orderDiffs = 0;
  for (const [k, list] of ea) {
    const other = eb.get(k);
    if (!other) {
      onlyA.push(k);
      continue;
    }
    for (let i = 0; i < Math.min(list.length, other.length); i++) {
      if (list[i].e !== other[i].e) orderDiffs++;
      for (const f of [3, 4, 5, 6, 8]) {
        const d = Math.abs(list[i].r[f] - other[i].r[f]);
        if (d > maxDiff) {
          maxDiff = d;
          worst = `${k} field ${f}: ${list[i].r[f]} vs ${other[i].r[f]}`;
        }
      }
    }
    if (list.length !== other.length) onlyA.push(`${k} x${list.length} vs x${other.length}`);
  }
  for (const k of eb.keys()) if (!ea.has(k)) onlyB.push(k);
  out.push(`edge rows only in A: ${onlyA.length}, only in B: ${onlyB.length}, shared rows at another index: ${orderDiffs}`);
  if (!quiet) {
    for (const k of onlyA.slice(0, 8)) out.push(`  A only: ${k}`);
    for (const k of onlyB.slice(0, 8)) out.push(`  B only: ${k}`);
  }
  out.push(`largest float difference on shared edges: ${maxDiff}${worst ? ` (${worst})` : ''}`);
  if (onlyA.length || onlyB.length || maxDiff > 1e-9) same = false;
  return { same, out };
}

function readDist(file) {
  const b = fs.readFileSync(file);
  const magic = b.toString('latin1', 0, 8);
  const [version, n, m, present, count] = [8, 12, 16, 20, 24].map((o) => b.readUInt32LE(o));
  const tables = [];
  let at = 28;
  for (let t = 0; t < count; t++) {
    const key = b.readUInt32LE(at);
    at += 4;
    const cost = new Uint32Array(n * n);
    for (let i = 0; i < n * n; i++, at += 4) cost[i] = b.readUInt32LE(at);
    const next = new Uint16Array(n * n);
    for (let i = 0; i < n * n; i++, at += 2) next[i] = b.readUInt16LE(at);
    tables.push({ key, cost, next });
  }
  return { magic, version, n, m, present, count, tables, size: b.length, trailing: b.length - at, bytes: b };
}

function compareDist(aFile, bFile) {
  const a = readDist(aFile);
  const b = readDist(bFile);
  const out = [];
  let same = true;
  out.push(`dist bytes ${a.bytes.equals(b.bytes) ? 'IDENTICAL' : 'differ'} (${a.size} vs ${b.size})`);
  const head = (d) => `${d.magic} v${d.version} n${d.n} m${d.m} present${d.present} tables${d.count} trailing${d.trailing}`;
  out.push(`  ${head(a)}`);
  out.push(`  ${head(b)}`);
  if (head(a) !== head(b)) return { same: false, out };
  for (let t = 0; t < a.count; t++) {
    const ta = a.tables[t];
    const tb = b.tables[t];
    let costDiff = 0;
    let maxCost = 0;
    let reach = 0;
    let hopDiff = 0;
    for (let i = 0; i < ta.cost.length; i++) {
      if (ta.cost[i] !== tb.cost[i]) {
        costDiff++;
        const unreachable = ta.cost[i] === 4294967295 || tb.cost[i] === 4294967295;
        if (unreachable) reach++;
        else maxCost = Math.max(maxCost, Math.abs(ta.cost[i] - tb.cost[i]));
      }
      if (ta.next[i] !== tb.next[i]) hopDiff++;
    }
    out.push(`  table key ${ta.key}/${tb.key}: costs differ ${costDiff} (reachability ${reach}, largest ${maxCost}/16), hops differ ${hopDiff} of ${ta.cost.length}`);
    if (ta.key !== tb.key || costDiff) same = false;
  }
  return { same, out };
}

function main() {
  const args = process.argv.slice(2);
  const quiet = args.includes('--quiet');
  const di = args.indexOf('--dist');
  const files = args.filter((x, i) => !x.startsWith('--') && (di < 0 || (i !== di + 1 && i !== di + 2)));
  if (files.length < 2) {
    console.error('usage: node tools/navcompare.js <a.txt> <b.txt> [--dist <a.dist> <b.dist>] [--quiet]');
    process.exit(2);
  }
  const g = compareGraphs(files[0], files[1], quiet);
  console.log(g.out.join('\n'));
  let same = g.same;
  if (di >= 0) {
    const d = compareDist(args[di + 1], args[di + 2]);
    console.log(d.out.join('\n'));
    same = same && d.same;
  }
  console.log(same ? 'SAME GRAPH' : 'DIFFERENT');
  process.exit(same ? 0 : 1);
}

if (require.main === module) main();
module.exports = { readGraph, readDist };
