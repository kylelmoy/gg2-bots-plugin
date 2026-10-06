#!/usr/bin/env node
//=============================================================================
// convert-policy.js - turn gg2-rl policy checkpoints (.npz) into files the
// plugin's GML loads with ds_grid_read.
//
//   node tools/convert-policy.js [checkpoint.npz | dir]... [--out <dir>] [--ignore-stamp]
//
// With no inputs it converts every .npz in gg2-server's checkpoints/ (the
// shipped bundle: tier0_combat4_s2 and tier2_pyro_rest3_s0). Output goes to
// build/data/policy/<label>.txt, which tools/build.js copies into the plugin
// as Plugins/bots/policy/. docs/POLICY.md describes the format; this header
// is the short form.
//
// What it checks, and refuses on, is what PolicyNetwork.Load checks: at least
// seven metadata fields, the simulation stamp (the gg2-server build whose
// ObservationWriter the GML port transcribes; --ignore-stamp is the C#'s
// ignoreSimulationStamp), action encoding 2, observation layout 2, 211
// observation floats, head shape 3,2,2,3,15,2, layers that chain and end at
// 27 outputs. The class set is meta[7] (comma-separated PlayerClass names),
// falling back to PolicyNetwork.DefaultTrainedClasses when absent or empty.
//
// Each layer's weights become one ds_grid in the orientation the GML forward
// pass wants (botPolicyNetAct): layer L even is <outputs> wide and <inputs>
// high (cell x=j, y=i is W[i][j]); layer L odd is <inputs> wide and <outputs>
// high (cell x=i, y=j is W[i][j]). Alternating means each layer's reduction
// leaves its outputs already laid out the way the next layer reads its inputs,
// so the GML never transposes. Biases are a row (L even) or a column (L odd).
//
// The file ends with a test vector: an observation and the logits the network
// gives for it, computed here in double precision. botPolicyNetLoad runs the
// GML forward pass on it at server start and refuses the checkpoint if the
// logits disagree, so a ds_grid semantic this file assumed wrongly is caught
// live before any bot uses it. This tool also checks the layout by emulating
// the GML algorithm on the grids it wrote, and reports how often double
// precision changes an argmax against the C#'s float32 arithmetic.
//
// Node standard library only. .npz is a zip of .npy files; both are parsed
// here (stored or deflated members; little-endian f4/f8 arrays; the metadata
// pickle exactly as gg2-server's NpyFile.ReadStrings reads it).
//=============================================================================

'use strict';

const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const ROOT = path.resolve(__dirname, '..');
const DEFAULT_SRC = path.join(process.env.GG2_SERVER || 'D:/Code/gg2-server', 'checkpoints');
const DEFAULT_OUT = path.join(ROOT, 'build', 'data', 'policy');

// What this port was written against: gg2-server's SimulationStamp and
// ObservationWriter/ActionDecoder at the build that shipped the checkpoints.
const EXPECTED_SIM_UUID = 'f10afbdadc795d77';
const ACTION_ENCODING = 2;
const OBSERVATION_LAYOUT = 2;
const OBSERVATION_LENGTH = 211;
const HEAD_SHAPE = [3, 2, 2, 3, 15, 2];
const FORMAT_VERSION = 1;

// PlayerClass, whose ordinals are GM8's CLASS_* constants (Constants.xml).
const CLASSES = ['SCOUT', 'SOLDIER', 'SNIPER', 'DEMOMAN', 'MEDIC', 'ENGINEER', 'HEAVY', 'SPY', 'PYRO', 'QUOTE'];
const DEFAULT_TRAINED = ['SCOUT', 'SOLDIER', 'DEMOMAN', 'HEAVY'];

// ---------------------------------------------------------------------------
// .npz (zip) and .npy

function readZip(buf, file) {
  const eocd = buf.lastIndexOf(Buffer.from([0x50, 0x4b, 0x05, 0x06]));
  if (eocd < 0) throw new Error(`${file}: not a zip archive`);
  const count = buf.readUInt16LE(eocd + 10);
  let at = buf.readUInt32LE(eocd + 16);
  const entries = new Map();
  for (let i = 0; i < count; i++) {
    if (buf.readUInt32LE(at) !== 0x02014b50) throw new Error(`${file}: bad central directory`);
    const method = buf.readUInt16LE(at + 10);
    const csize = buf.readUInt32LE(at + 20);
    const usize = buf.readUInt32LE(at + 24);
    const nlen = buf.readUInt16LE(at + 28);
    const xlen = buf.readUInt16LE(at + 30);
    const clen = buf.readUInt16LE(at + 32);
    const local = buf.readUInt32LE(at + 42);
    const name = buf.toString('utf8', at + 46, at + 46 + nlen);
    if (csize === 0xffffffff || usize === 0xffffffff) throw new Error(`${file}: zip64 members are not supported`);
    const lnlen = buf.readUInt16LE(local + 26);
    const lxlen = buf.readUInt16LE(local + 28);
    const start = local + 30 + lnlen + lxlen;
    const data = buf.subarray(start, start + csize);
    let raw;
    if (method === 0) raw = Buffer.from(data);
    else if (method === 8) raw = zlib.inflateRawSync(data);
    else throw new Error(`${file}: member ${name} uses compression method ${method}`);
    if (raw.length !== usize) throw new Error(`${file}: member ${name} is ${raw.length} bytes, expected ${usize}`);
    entries.set(name.endsWith('.npy') ? name.slice(0, -4) : name, raw);
    at += 46 + nlen + xlen + clen;
  }
  return entries;
}

function npyHeader(npy) {
  const magic = [0x93, 0x4e, 0x55, 0x4d, 0x50, 0x59];
  if (npy.length < 10 || magic.some((b, i) => npy[i] !== b)) throw new Error('not a .npy file');
  const major = npy[6];
  const len = major === 1 ? npy.readUInt16LE(8) : npy.readUInt32LE(8);
  const at = major === 1 ? 10 : 12;
  return { header: npy.toString('latin1', at, at + len), data: at + len };
}

function npyField(header, key) {
  const marker = `'${key}':`;
  const at = header.indexOf(marker);
  if (at < 0) throw new Error(`the .npy header has no '${key}'`);
  const rest = header.slice(at + marker.length).trimStart();
  if (rest.startsWith("'")) return rest.slice(1, rest.indexOf("'", 1));
  const stop = rest.search(/[,}]/);
  return rest.slice(0, stop).trim();
}

function npyShape(header) {
  const at = header.indexOf("'shape':");
  const open = header.indexOf('(', at);
  const close = header.indexOf(')', open);
  const inside = header.slice(open + 1, close).trim();
  return inside ? inside.split(',').map((s) => s.trim()).filter(Boolean).map(Number) : [];
}

// A 1-D or 2-D float array, as float64 values (f4 widened exactly).
function readArray(npy) {
  const { header, data } = npyHeader(npy);
  const descr = npyField(header, 'descr');
  if (npyField(header, 'fortran_order') !== 'False') throw new Error('a Fortran-ordered array is refused');
  const shape = npyShape(header);
  if (shape.length < 1 || shape.length > 2) throw new Error(`only 1-D and 2-D arrays are read, got ${shape.length}-D`);
  const rows = shape.length === 1 ? 1 : shape[0];
  const cols = shape.length === 1 ? shape[0] : shape[1];
  const values = new Float64Array(rows * cols);
  for (let i = 0; i < values.length; i++) {
    if (descr === '<f4') values[i] = npy.readFloatLE(data + i * 4);
    else if (descr === '<f8') values[i] = Math.fround(npy.readDoubleLE(data + i * 8)); // the C# narrows f8 to float
    else throw new Error(`dtype '${descr}' is not one this reader handles`);
  }
  return { rows, cols, values };
}

// The metadata: a pickled 1-D object array of strings. A transcription of
// NpyFile.ReadStrings, which locks on to numpy's element list
// (NEWFALSE EMPTY_LIST MEMOIZE MARK) and follows the memo for repeats.
function readStrings(npy) {
  const { header, data } = npyHeader(npy);
  const descr = npyField(header, 'descr');
  if (descr !== '|O' && descr !== '|O8') throw new Error('the metadata is not an object array');
  const shape = npyShape(header);
  if (shape.length !== 1) throw new Error(`the metadata is 1-D, got ${shape.length}-D`);
  const needle = Buffer.from([0x89, 0x5d, 0x94, 0x28]);
  const start = npy.indexOf(needle, data);
  if (start < 0) throw new Error('no element list found in the metadata pickle');
  let memo = countMemoSlots(npy, data, start + 2) + 1;
  let at = start + 4;
  const found = [];
  const byIndex = new Map();
  while (at < npy.length) {
    let value;
    if (npy[at] === 0x8c) {
      const len = npy[at + 1];
      value = npy.toString('utf8', at + 2, at + 2 + len);
      at += 2 + len;
      if (at < npy.length && npy[at] === 0x94) {
        byIndex.set(memo, value);
        memo++;
        at++;
      }
    } else if (npy[at] === 0x68 || npy[at] === 0x6a) {
      const wide = npy[at] === 0x6a;
      const slot = wide ? npy.readInt32LE(at + 1) : npy[at + 1];
      if (!byIndex.has(slot)) throw new Error(`the metadata references memo slot ${slot}, which this element list did not write`);
      value = byIndex.get(slot);
      at += wide ? 5 : 2;
    } else {
      break;
    }
    found.push(value);
  }
  if (at >= npy.length || npy[at] !== 0x65) throw new Error("the metadata's element list did not end at APPENDS");
  if (found.length !== shape[0]) throw new Error(`the metadata header says ${shape[0]} elements and the pickle held ${found.length}`);
  return found;
}

function countMemoSlots(npy, from, limit) {
  let at = from;
  let slots = 0;
  const zero = new Set([0x28, 0x29, 0x2e, 0x4e, 0x52, 0x5d, 0x61, 0x62, 0x65, 0x73, 0x74, 0x75, 0x7d, 0x85, 0x86, 0x87, 0x88, 0x89, 0x93]);
  while (at < limit) {
    const op = npy[at];
    if (op === 0x94) { slots++; at += 1; } else if (op === 0x71) { slots++; at += 2; } else if (op === 0x72) { slots++; at += 5; } else if (op === 0x80) at += 2;
    else if (op === 0x95) at += 9;
    else if (op === 0x8c || op === 0x43) at += 2 + npy[at + 1];
    else if (op === 0x58 || op === 0x42) at += 5 + npy.readInt32LE(at + 1);
    else if (op === 0x4b) at += 2;
    else if (op === 0x4d) at += 3;
    else if (op === 0x4a) at += 5;
    else if (op === 0x68) at += 2;
    else if (op === 0x6a) at += 5;
    else if (zero.has(op)) at += 1;
    else throw new Error(`unknown pickle opcode 0x${op.toString(16)} at ${at} while counting memo slots`);
  }
  return slots;
}

// ---------------------------------------------------------------------------
// The checkpoint

function loadCheckpoint(file, ignoreStamp) {
  const entries = readZip(fs.readFileSync(file), file);
  if (!entries.has('meta')) throw new Error('the checkpoint has no metadata; it cannot be checked and is refused');
  const meta = readStrings(entries.get('meta'));
  if (meta.length < 7) throw new Error(`the metadata has ${meta.length} fields, expected at least 7`);
  const [policyVersion, simUuid, encodingText, layoutText, headText, obsText, repeatText] = meta;
  const encoding = parseInt(encodingText, 10);
  const layout = parseInt(layoutText, 10);
  const heads = headText.split(',').map((s) => s.trim()).filter(Boolean).map((s) => parseInt(s, 10));
  const obsLength = parseInt(obsText, 10);
  const repeat = parseInt(repeatText, 10);
  const classNames = meta.length > 7 && meta[7].length > 0
    ? meta[7].split(',').map((s) => s.trim()).filter(Boolean)
    : DEFAULT_TRAINED.slice();
  const classes = classNames.map((name) => {
    const k = CLASSES.indexOf(name.toUpperCase());
    if (k < 0) throw new Error(`the checkpoint says it was trained on '${name}', which is not a class`);
    return k;
  });

  if (simUuid !== EXPECTED_SIM_UUID) {
    const msg = `this policy was trained against simulation ${simUuid}, and this port transcribes ${EXPECTED_SIM_UUID}`;
    if (!ignoreStamp) throw new Error(msg);
    console.warn(`WARNING: ${msg} (--ignore-stamp)`);
  }
  if (encoding !== ACTION_ENCODING) throw new Error(`policy action encoding v${encoding} against this port's v${ACTION_ENCODING}`);
  if (layout !== OBSERVATION_LAYOUT) throw new Error(`policy observation layout v${layout} against this port's v${OBSERVATION_LAYOUT}`);
  if (obsLength !== OBSERVATION_LENGTH) throw new Error(`policy wants ${obsLength} observation floats, this port writes ${OBSERVATION_LENGTH}`);
  if (heads.join(',') !== HEAD_SHAPE.join(',')) throw new Error(`policy head shape [${heads}] against this port's [${HEAD_SHAPE}]`);
  if (!(repeat >= 1)) throw new Error(`action repeat '${repeatText}' is not a positive integer`);

  const layers = [];
  let inputs = obsLength;
  for (let L = 0; entries.has(`w${L}`); L++) {
    const w = readArray(entries.get(`w${L}`));
    const b = readArray(entries.get(`b${L}`));
    if (w.rows !== inputs) throw new Error(`layer ${L} takes ${w.rows} inputs where the previous layer gives ${inputs}`);
    if (b.values.length !== w.cols) throw new Error(`layer ${L} has ${w.cols} outputs and ${b.values.length} biases`);
    layers.push({ inputs: w.rows, outputs: w.cols, w: w.values, b: b.values });
    inputs = w.cols;
  }
  if (layers.length === 0) throw new Error('the checkpoint has no layers');
  const outputs = HEAD_SHAPE.reduce((a, b) => a + b, 0);
  if (inputs !== outputs) throw new Error(`the output layer is ${inputs} wide and the heads want ${outputs}`);

  return { policyVersion, simUuid, encoding, layout, heads, obsLength, repeat, classes, classNames, layers };
}

// ---------------------------------------------------------------------------
// Forward passes: the C#'s (float32), plain double, and the GML grid method

function forwardFloat32(net, obs) {
  let cur = Float32Array.from(obs);
  net.layers.forEach((layer, L) => {
    const out = Float32Array.from(layer.b);
    for (let i = 0; i < layer.inputs; i++) {
      const x = cur[i];
      if (x === 0) continue;
      for (let j = 0; j < layer.outputs; j++) out[j] = Math.fround(out[j] + Math.fround(x * layer.w[i * layer.outputs + j]));
    }
    if (L < net.layers.length - 1) for (let j = 0; j < out.length; j++) if (out[j] < 0) out[j] = 0;
    cur = out;
  });
  return Array.from(cur);
}

function forwardDouble(net, obs) {
  let cur = obs.slice();
  net.layers.forEach((layer, L) => {
    const out = Array.from(layer.b);
    for (let i = 0; i < layer.inputs; i++) {
      const x = cur[i];
      if (x === 0) continue;
      for (let j = 0; j < layer.outputs; j++) out[j] += x * layer.w[i * layer.outputs + j];
    }
    if (L < net.layers.length - 1) for (let j = 0; j < out.length; j++) if (out[j] < 0) out[j] = 0;
    cur = out;
  });
  return cur;
}

function argmaxHeads(logits) {
  const heads = [];
  let at = 0;
  for (const width of HEAD_SHAPE) {
    let best = 0;
    for (let i = 1; i < width; i++) if (logits[at + i] > logits[at + best]) best = i;
    heads.push(best);
    at += width;
  }
  return heads;
}

// A ds_grid as GM8 holds it: column-major, grid[x][y].
function makeGrid(w, h) {
  return { w, h, c: new Float64Array(w * h) };
}
const gget = (g, x, y) => g.c[x * g.h + y];
const gset = (g, x, y, v) => { g.c[x * g.h + y] = v; };

// ds_grid_set_grid_region / add / multiply, with a snapshot of the source
// region first, so an overlapping same-grid call would still be well defined.
function gridOp(dst, src, x1, y1, x2, y2, xp, yp, op) {
  const snap = [];
  for (let x = x1; x <= x2; x++) for (let y = y1; y <= y2; y++) snap.push(gget(src, x, y));
  let k = 0;
  for (let x = x1; x <= x2; x++) {
    for (let y = y1; y <= y2; y++) {
      const v = snap[k++];
      const dx = xp + x - x1;
      const dy = yp + y - y1;
      if (op === 'set') gset(dst, dx, dy, v);
      else if (op === 'add') gset(dst, dx, dy, gget(dst, dx, dy) + v);
      else gset(dst, dx, dy, gget(dst, dx, dy) * v);
    }
  }
}

// What botPolicyNetAct does, call for call, on the grids this tool writes.
function forwardGrid(grids, obsGrid) {
  const n = grids.length;
  let prev = null;
  for (let L = 0; L < n; L++) {
    const { w, b, inputs: nin, outputs: nout } = grids[L];
    const t = makeGrid(w.w, w.h);
    if (L % 2 === 0) {
      gridOp(t, L === 0 ? obsGrid : prev, 0, 0, 0, nin - 1, 0, 0, 'set');
      for (let c = 1; c < nout;) { const k = Math.min(c, nout - c); gridOp(t, t, 0, 0, k - 1, nin - 1, c, 0, 'set'); c += k; }
      gridOp(t, w, 0, 0, nout - 1, nin - 1, 0, 0, 'mul');
      for (let h = nin; h > 1;) { const k = Math.floor(h / 2); gridOp(t, t, 0, h - k, nout - 1, h - 1, 0, 0, 'add'); h -= k; }
      gridOp(t, b, 0, 0, nout - 1, 0, 0, 0, 'add');
      if (L < n - 1) for (let i = 0; i < nout; i++) if (gget(t, i, 0) < 0) gset(t, i, 0, 0);
    } else {
      gridOp(t, prev, 0, 0, nin - 1, 0, 0, 0, 'set');
      for (let c = 1; c < nout;) { const k = Math.min(c, nout - c); gridOp(t, t, 0, 0, nin - 1, k - 1, 0, c, 'set'); c += k; }
      gridOp(t, w, 0, 0, nin - 1, nout - 1, 0, 0, 'mul');
      for (let h = nin; h > 1;) { const k = Math.floor(h / 2); gridOp(t, t, h - k, 0, h - 1, nout - 1, 0, 0, 'add'); h -= k; }
      gridOp(t, b, 0, 0, 0, nout - 1, 0, 0, 'add');
      if (L < n - 1) for (let i = 0; i < nout; i++) if (gget(t, 0, i) < 0) gset(t, 0, i, 0);
    }
    prev = t;
  }
  const out = [];
  const last = grids[n - 1].outputs;
  for (let i = 0; i < last; i++) out.push((n - 1) % 2 === 0 ? gget(prev, i, 0) : gget(prev, 0, i));
  return out;
}

// ---------------------------------------------------------------------------
// ds_grid_write hex: uint32 601, uint32 width, uint32 height, then width*height
// cells column-major (x * height + y), each 16 bytes: uint32 0 (a real), the
// double, uint32 0. Upper-case hex, as GM8 writes it and NavCache.ReadGrid
// reads it.

function gridHex(g) {
  const buf = Buffer.alloc(12 + 16 * g.w * g.h);
  buf.writeUInt32LE(601, 0);
  buf.writeUInt32LE(g.w, 4);
  buf.writeUInt32LE(g.h, 8);
  for (let i = 0; i < g.w * g.h; i++) {
    const o = 12 + 16 * i;
    buf.writeUInt32LE(0, o);
    buf.writeDoubleLE(g.c[i], o + 4);
    buf.writeUInt32LE(0, o + 12);
  }
  return buf.toString('hex').toUpperCase();
}

function parseGridHex(hex) {
  const buf = Buffer.from(hex, 'hex');
  if (buf.readUInt32LE(0) !== 601) throw new Error('grid tag is not 601');
  const g = makeGrid(buf.readUInt32LE(4), buf.readUInt32LE(8));
  for (let i = 0; i < g.w * g.h; i++) {
    if (buf.readUInt32LE(12 + 16 * i) !== 0) throw new Error('grid cell is not a real');
    g.c[i] = buf.readDoubleLE(12 + 16 * i + 4);
  }
  return g;
}

function layerGrids(net) {
  return net.layers.map((layer, L) => {
    const even = L % 2 === 0;
    const w = even ? makeGrid(layer.outputs, layer.inputs) : makeGrid(layer.inputs, layer.outputs);
    const b = even ? makeGrid(layer.outputs, 1) : makeGrid(1, layer.outputs);
    for (let i = 0; i < layer.inputs; i++) {
      for (let j = 0; j < layer.outputs; j++) {
        const v = layer.w[i * layer.outputs + j];
        if (even) gset(w, j, i, v); else gset(w, i, j, v);
      }
    }
    for (let j = 0; j < layer.outputs; j++) {
      if (even) gset(b, j, 0, layer.b[j]); else gset(b, 0, j, layer.b[j]);
    }
    return { w, b, inputs: layer.inputs, outputs: layer.outputs };
  });
}

// ---------------------------------------------------------------------------
// Observations for the checks: shaped like ObservationWriter's, not uniform
// noise, so the hidden layers see realistic activations.

function rng(seed) {
  let s = seed >>> 0;
  return () => {
    s = (Math.imul(s, 1664525) + 1013904223) >>> 0;
    return s / 4294967296;
  };
}

function sampleObservation(rand, cls) {
  const o = new Array(OBSERVATION_LENGTH).fill(0);
  const u = (a, b) => a + (b - a) * rand();
  const angle = () => u(0, 2 * Math.PI);
  o[cls] = 1;
  o[9] = u(0.1, 1);
  o[10] = u(-0.6, 0.6);
  o[11] = u(-0.8, 0.8);
  o[12] = rand() < 0.6 ? 1 : 0;
  let a = angle();
  o[13] = Math.sin(a); o[14] = Math.cos(a);
  o[15] = u(0, 1); o[16] = rand() < 0.3 ? u(0, 1) : 0; o[17] = rand() < 0.5 ? 1 : 0; o[18] = o[17] ? 0 : u(0, 1);
  for (let e = 0; e < 2; e++) {
    if (e === 1 && rand() < 0.3) continue;
    const base = 20 + 18 * e;
    o[base] = 1; o[base + 1] = u(-1, 1); o[base + 2] = u(-0.6, 0.6); o[base + 3] = u(-0.8, 0.8); o[base + 4] = u(-0.8, 0.8);
    o[base + 5 + Math.floor(rand() * 9)] = 1;
    o[base + 14] = u(0.1, 1);
    a = angle(); o[base + 15] = Math.sin(a); o[base + 16] = Math.cos(a);
  }
  const shots = Math.floor(rand() * 5);
  for (let p = 0; p < shots; p++) {
    const base = 56 + 15 * p;
    o[base] = 1; o[base + 1] = u(-1, 1); o[base + 2] = u(-1, 1); o[base + 3] = u(-1, 1); o[base + 4] = u(-1, 1);
    o[base + 5 + Math.floor(rand() * 9)] = 1;
    o[base + 14] = rand() < 0.5 ? 1 : 0;
  }
  for (let r = 0; r < 24; r++) o[116 + r] = rand() < 0.4 ? 1 : Math.round(u(1, 80)) * 4 / 320;
  for (let c = 0; c < 64; c++) o[140 + c] = rand() < 0.3 ? 1 : 0;
  const dx = u(-1, 1), dy = u(-1, 1), d = Math.hypot(dx, dy);
  o[204] = dy / d; o[205] = dx / d; o[206] = Math.min(d * u(0.2, 1), 1); o[207] = 1;
  return o;
}

// ---------------------------------------------------------------------------

function convert(file, outDir, ignoreStamp) {
  const label = path.basename(file, '.npz');
  const net = loadCheckpoint(file, ignoreStamp);
  const grids = layerGrids(net);

  const rand = rng(0x6a2b1d ^ label.length);
  const testObs = sampleObservation(rand, net.classes[0] < 9 ? net.classes[0] : 0);
  const expected = forwardDouble(net, testObs);
  const expectedHeads = argmaxHeads(expected);

  const obsGrid = makeGrid(1, OBSERVATION_LENGTH);
  testObs.forEach((v, i) => gset(obsGrid, 0, i, v));
  const logitGrid = makeGrid(expected.length, 1);
  expected.forEach((v, i) => gset(logitGrid, i, 0, v));

  const lines = [
    'gg2policy',
    String(FORMAT_VERSION),
    label,
    net.policyVersion,
    net.simUuid,
    String(net.encoding),
    String(net.layout),
    net.heads.join(','),
    String(net.obsLength),
    String(net.repeat),
    net.classes.join(','),
    net.classNames.join(','),
    String(grids.length),
  ];
  for (const g of grids) {
    lines.push(String(g.inputs), String(g.outputs), gridHex(g.w), gridHex(g.b));
  }
  lines.push(gridHex(obsGrid), gridHex(logitGrid), expectedHeads.join(','));

  fs.mkdirSync(outDir, { recursive: true });
  const out = path.join(outDir, `${label}.txt`);
  fs.writeFileSync(out, lines.join('\r\n') + '\r\n', 'latin1');

  // Read back what was written and run the GML method on it.
  const text = fs.readFileSync(out, 'latin1').split('\r\n');
  let at = 13;
  const back = [];
  for (let L = 0; L < grids.length; L++) {
    const inputs = Number(text[at]); const outputs = Number(text[at + 1]);
    back.push({ inputs, outputs, w: parseGridHex(text[at + 2]), b: parseGridHex(text[at + 3]) });
    at += 4;
  }
  const backObs = parseGridHex(text[at]);
  const viaGrid = forwardGrid(back, backObs);
  let gridErr = 0;
  viaGrid.forEach((v, i) => { gridErr = Math.max(gridErr, Math.abs(v - expected[i])); });
  if (gridErr > 1e-9) throw new Error(`the grid method disagrees with the dense pass by ${gridErr}`);

  // How often double precision moves an argmax against the C#'s float32.
  const sampler = rng(12345);
  let flips = 0;
  const N = 20000;
  let maxDiff = 0;
  for (let k = 0; k < N; k++) {
    const obs = sampleObservation(sampler, net.classes[k % net.classes.length] % 9);
    const f = forwardFloat32(net, obs);
    const d = forwardDouble(net, obs);
    f.forEach((v, i) => { maxDiff = Math.max(maxDiff, Math.abs(v - d[i])); });
    if (argmaxHeads(f).join() !== argmaxHeads(d).join()) flips++;
  }

  console.log(`${label}: ${net.layers.map((l) => `${l.inputs}x${l.outputs}`).join(' -> ')}, repeat ${net.repeat}, `
    + `stamp ${net.simUuid}${net.simUuid === EXPECTED_SIM_UUID ? ' (match)' : ' (MISMATCH, ignored)'}, drives ${net.classNames.join(',')}`);
  console.log(`  -> ${path.relative(ROOT, out)} (${fs.statSync(out).size} bytes); grid method vs dense: ${gridErr.toExponential(2)}; `
    + `float32 vs double: max logit diff ${maxDiff.toExponential(2)}, argmax differs in ${flips}/${N} sampled observations`);
}

function main() {
  const args = process.argv.slice(2);
  let outDir = DEFAULT_OUT;
  let ignoreStamp = false;
  const inputs = [];
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--out') outDir = path.resolve(args[++i]);
    else if (args[i] === '--ignore-stamp') ignoreStamp = true;
    else inputs.push(args[i]);
  }
  if (inputs.length === 0) inputs.push(DEFAULT_SRC);
  const files = [];
  for (const p of inputs) {
    if (fs.statSync(p).isDirectory()) {
      for (const f of fs.readdirSync(p).sort()) if (f.endsWith('.npz')) files.push(path.join(p, f));
    } else {
      files.push(p);
    }
  }
  if (files.length === 0) {
    console.error('convert-policy: no .npz checkpoints found');
    process.exit(1);
  }
  let failed = 0;
  for (const f of files) {
    try {
      convert(f, outDir, ignoreStamp);
    } catch (e) {
      failed++;
      console.error(`${path.basename(f)}: REFUSED: ${e.message}`);
    }
  }
  process.exit(failed ? 1 : 0);
}

if (require.main === module) main();
module.exports = { loadCheckpoint, readZip, readStrings, gridHex, parseGridHex };
