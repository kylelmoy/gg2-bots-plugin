#!/usr/bin/env node
//=============================================================================
// botc.js - turn the plugin's GML source into GML a plugin can load.
//
// A GG2 plugin cannot define scripts: it runs once through execute_file and can
// only attach code to objects with object_event_add. execute_string recompiles
// its argument on every call, which is far too slow for a bot layer that makes
// thousands of calls a tick. So every source file under src/fn/ becomes the
// User Event 0 of an object of its own, compiled once when the plugin loads,
// and a call becomes
//
//     global.botA0 = (a); global.botA1 = (b);
//     event_perform_object(global.botF_name, ev_other, ev_user0);
//     x = global.botRet;
//
// event_perform_object runs another object's event as the CURRENT instance, so
// `self` inside a function is whoever called it, exactly as with a script.
//
// The rules a source file has to follow, which this file enforces:
//
// - A function is src/fn/**/<name>.gml, and <name> starts with `bot` or `nav`
//   followed by a capital, so it cannot collide with a game script or builtin.
//   It reads argument0..argument15 and may `return expr;` or `return;`.
// - A call to a function may only be a whole statement, in one of three shapes:
//       name(args);            x = name(args);            return name(args);
//   where x is an lvalue (`a`, `a.b`, `a[i]`, `global.a`, `a.b[i, j]`). A call
//   inside a larger expression - `if (name(x))`, `y = name(x) + 1`, an argument
//   of another call - is a build error. Hoist it into its own statement.
// - `argumentN` inside a function is read once into a local at entry, so a
//   function may call others freely; `argument[N]` and `argument_count` are
//   refused.
// - A function that hands back more than one value sets global.botRetX etc.
//   itself; the caller reads them immediately after the call.
//
// Line numbers are preserved (every replacement keeps its newlines), so a lint
// error in the output points at the same line of the source file.
//=============================================================================

'use strict';

const NAME_RE = /^(bot|nav)[A-Z][A-Za-z0-9_]*$/;
const BOUNDARY_WORDS = new Set(['else', 'do', 'then', 'begin', 'end']);
const MAX_ARGS = 16;

// ---------------------------------------------------------------------------
// Tokenizer. Comments and whitespace are kept as tokens so the output is the
// input with only the call statements rewritten.

function tokenize(src, file) {
  const toks = [];
  let i = 0;
  let line = 1;
  const n = src.length;
  const push = (type, start, end) => {
    const text = src.slice(start, end);
    toks.push({ type, text, start, end, line });
    for (let k = start; k < end; k++) if (src.charCodeAt(k) === 10) line++;
  };
  while (i < n) {
    const c = src[i];
    const start = i;
    if (c === ' ' || c === '\t' || c === '\r' || c === '\n') {
      while (i < n && /[ \t\r\n]/.test(src[i])) i++;
      push('ws', start, i);
    } else if (c === '/' && src[i + 1] === '/') {
      while (i < n && src[i] !== '\n') i++;
      push('comment', start, i);
    } else if (c === '/' && src[i + 1] === '*') {
      const close = src.indexOf('*/', i + 2);
      if (close < 0) throw new Error(`${file}:${line}: unterminated /* comment`);
      i = close + 2;
      push('comment', start, i);
    } else if (c === '"' || c === "'") {
      // GM8 strings have no escapes and may span lines.
      const close = src.indexOf(c, i + 1);
      if (close < 0) throw new Error(`${file}:${line}: unterminated string`);
      i = close + 1;
      push('string', start, i);
    } else if (/[A-Za-z_]/.test(c)) {
      while (i < n && /[A-Za-z0-9_]/.test(src[i])) i++;
      push('ident', start, i);
    } else if (/[0-9]/.test(c) || (c === '.' && /[0-9]/.test(src[i + 1] || ''))) {
      while (i < n && /[0-9.]/.test(src[i])) i++;
      push('number', start, i);
    } else if (c === '$') {
      i++;
      while (i < n && /[0-9A-Fa-f]/.test(src[i])) i++;
      push('number', start, i);
    } else {
      const two = src.slice(i, i + 2);
      if (['==', '!=', '<=', '>=', '&&', '||', '^^', '+=', '-=', '*=', '/=', '|=', '&=', '^=', ':=', '<<', '>>', '<>'].includes(two)) {
        i += 2;
      } else {
        i += 1;
      }
      push('punct', start, i);
    }
  }
  return toks;
}

const sig = (t) => t.type !== 'ws' && t.type !== 'comment';

function nextSig(toks, i) {
  for (let k = i + 1; k < toks.length; k++) if (sig(toks[k])) return k;
  return -1;
}

function prevSig(toks, i) {
  for (let k = i - 1; k >= 0; k--) if (sig(toks[k])) return k;
  return -1;
}

// Index of the token closing the bracket opened at `open`.
function matchForward(toks, open, file) {
  const o = toks[open].text;
  const c = o === '(' ? ')' : o === '[' ? ']' : '}';
  let depth = 0;
  for (let k = open; k < toks.length; k++) {
    if (!sig(toks[k])) continue;
    const t = toks[k].text;
    if (t === '(' || t === '[' || t === '{') depth++;
    else if (t === ')' || t === ']' || t === '}') {
      depth--;
      if (depth === 0) {
        if (t !== c) throw new Error(`${file}:${toks[k].line}: mismatched '${t}'`);
        return k;
      }
    }
  }
  throw new Error(`${file}:${toks[open].line}: unclosed '${o}'`);
}

function matchBackward(toks, close, file) {
  let depth = 0;
  for (let k = close; k >= 0; k--) {
    if (!sig(toks[k])) continue;
    const t = toks[k].text;
    if (t === ')' || t === ']' || t === '}') depth++;
    else if (t === '(' || t === '[' || t === '{') {
      depth--;
      if (depth === 0) return k;
    }
  }
  throw new Error(`${file}:${toks[close].line}: unopened '${toks[close].text}'`);
}

// Can a statement start right after token k?
function isBoundary(toks, k) {
  if (k < 0) return true;
  const t = toks[k];
  if (t.type === 'punct' && [';', '{', '}', ')', ':'].includes(t.text)) return true;
  if (t.type === 'ident' && BOUNDARY_WORDS.has(t.text)) return true;
  return false;
}

// Walk back from `k` (the last token of a would-be lvalue) to its first token,
// or return -1 if what is there is not an lvalue.
function lvalueStart(toks, k) {
  let pos = k;
  let first = -1;
  for (;;) {
    if (pos < 0) return first;
    const t = toks[pos];
    if (t.type === 'punct' && t.text === ']') {
      const open = matchBackward(toks, pos, '');
      pos = prevSig(toks, open);
      if (pos < 0 || toks[pos].type !== 'ident') return -1;
      continue;
    }
    if (t.type === 'ident') {
      first = pos;
      const p = prevSig(toks, pos);
      if (p >= 0 && toks[p].text === '.') {
        const q = prevSig(toks, p);
        if (q < 0) return -1;
        if (toks[q].type === 'ident' || toks[q].text === ']' || toks[q].text === ')') {
          pos = q;
          if (toks[q].text === ')') {
            // (expr).field - an instance expression in parentheses
            const open = matchBackward(toks, q, '');
            first = open;
            return first;
          }
          continue;
        }
        return -1;
      }
      return first;
    }
    return -1;
  }
}

function text(toks, from, to) {
  let s = '';
  for (let k = from; k <= to; k++) s += toks[k].text;
  return s;
}

function newlines(s) {
  let c = 0;
  for (let k = 0; k < s.length; k++) if (s.charCodeAt(k) === 10) c++;
  return c;
}

// Split the tokens strictly between `open` and `close` at depth-0 commas.
function splitArgs(toks, open, close) {
  const args = [];
  let depth = 0;
  let from = open + 1;
  for (let k = open + 1; k < close; k++) {
    if (!sig(toks[k])) continue;
    const t = toks[k].text;
    if (t === '(' || t === '[' || t === '{') depth++;
    else if (t === ')' || t === ']' || t === '}') depth--;
    else if (t === ',' && depth === 0) {
      args.push([from, k - 1]);
      from = k + 1;
    }
  }
  const last = [from, close - 1];
  const hasContent = toks.slice(from, close).some(sig);
  if (hasContent || args.length) args.push(last);
  return args;
}

// ---------------------------------------------------------------------------

function transpile(src, file, funcs, { isFunction = false } = {}) {
  const toks = tokenize(src, file);
  const edits = []; // { from, to, replacement } over token indices, inclusive
  const errors = [];
  const consumedReturn = new Set();
  const err = (tok, msg) => errors.push(`${file}:${tok.line}: ${msg}`);

  for (let k = 0; k < toks.length; k++) {
    const t = toks[k];
    if (t.type !== 'ident') continue;
    if (t.text === 'argument_count' || (t.text === 'argument' && toks[nextSig(toks, k)]?.text === '[')) {
      err(t, `${t.text}${t.text === 'argument' ? '[...]' : ''} is not supported; use argument0..argument15`);
      continue;
    }
    if (!funcs.has(t.text)) continue;
    const open = nextSig(toks, k);
    if (open < 0 || toks[open].text !== '(') {
      err(t, `${t.text} is a plugin function and can only be called`);
      continue;
    }
    const p0 = prevSig(toks, k);
    if (p0 >= 0 && toks[p0].text === '.') {
      err(t, `${t.text} called as a field`);
      continue;
    }
    const close = matchForward(toks, open, file);
    const semi = nextSig(toks, close);
    if (semi < 0 || toks[semi].text !== ';') {
      err(t, `call to ${t.text} must be a whole statement ending in ';' (hoist it into its own statement)`);
      continue;
    }
    const args = splitArgs(toks, open, close);
    if (args.length > MAX_ARGS) {
      err(t, `call to ${t.text} has ${args.length} arguments; the limit is ${MAX_ARGS}`);
      continue;
    }
    for (const [a, b] of args) {
      for (let q = a; q <= b; q++) {
        if (toks[q].type === 'ident' && funcs.has(toks[q].text)) {
          err(toks[q], `call to ${toks[q].text} inside the arguments of ${t.text}; hoist it into its own statement`);
        }
      }
    }

    // What the call is part of.
    let stmtStart;
    let tail;
    const p = prevSig(toks, k);
    if (p >= 0 && toks[p].type === 'punct' && toks[p].text === '=') {
      const lvEnd = prevSig(toks, p);
      const lvStart = lvEnd < 0 ? -1 : lvalueStart(toks, lvEnd);
      if (lvStart < 0 || !isBoundary(toks, prevSig(toks, lvStart))) {
        err(t, `call to ${t.text} inside an expression; only 'x = ${t.text}(...);' is allowed`);
        continue;
      }
      stmtStart = lvStart;
      tail = ` ${text(toks, lvStart, lvEnd).replace(/\s+/g, ' ')} = global.botRet;`;
    } else if (p >= 0 && toks[p].type === 'ident' && toks[p].text === 'return') {
      if (!isFunction) {
        err(t, `return outside a function`);
        continue;
      }
      if (!isBoundary(toks, prevSig(toks, p))) {
        err(t, `return in an unexpected position`);
        continue;
      }
      stmtStart = p;
      consumedReturn.add(p);
      tail = ' exit;';
    } else if (isBoundary(toks, p)) {
      stmtStart = k;
      tail = '';
    } else {
      err(t, `call to ${t.text} inside an expression; hoist it into its own statement`);
      continue;
    }

    let body = '{';
    args.forEach(([a, b], idx) => {
      body += ` global.botA${idx} = (${text(toks, a, b).replace(/\s+/g, ' ').trim()});`;
    });
    body += ` event_perform_object(global.botF_${t.text}, ev_other, ev_user0);${tail} }`;
    const original = text(toks, stmtStart, semi);
    body += '\n'.repeat(newlines(original));
    edits.push({ from: stmtStart, to: semi, replacement: body });
    k = semi;
  }

  // Plain returns inside functions, and the argument locals.
  const usedArgs = new Set();
  if (isFunction) {
    for (let k = 0; k < toks.length; k++) {
      const t = toks[k];
      if (t.type !== 'ident') continue;
      const m = /^argument([0-9]+)$/.exec(t.text);
      if (m) {
        const idx = Number(m[1]);
        if (idx >= MAX_ARGS) err(t, `${t.text}: at most ${MAX_ARGS} arguments`);
        usedArgs.add(idx);
        continue;
      }
      if (t.text !== 'return' || consumedReturn.has(k)) continue;
      if (edits.some((e) => k >= e.from && k <= e.to)) continue;
      const after = nextSig(toks, k);
      if (after >= 0 && toks[after].text === ';') {
        edits.push({ from: k, to: after, replacement: 'exit;' });
        continue;
      }
      // return expr;  - the expression ends at the first depth-0 ';'
      let depth = 0;
      let end = -1;
      for (let q = after; q < toks.length; q++) {
        if (!sig(toks[q])) continue;
        const s = toks[q].text;
        if (s === '(' || s === '[' || s === '{') depth++;
        else if (s === ')' || s === ']' || s === '}') depth--;
        else if (s === ';' && depth === 0) { end = q; break; }
        if (depth < 0) break;
      }
      if (end < 0) {
        err(t, `return without a terminating ';'`);
        continue;
      }
      const original = text(toks, k, end);
      const expr = text(toks, after, end - 1).replace(/\s+/g, ' ').trim();
      edits.push({ from: k, to: end, replacement: `{ global.botRet = (${expr}); exit; }` + '\n'.repeat(newlines(original)) });
    }
  } else {
    for (const t of toks) {
      if (t.type === 'ident' && /^argument[0-9]+$/.test(t.text)) err(t, `${t.text} outside a function`);
    }
  }

  if (errors.length) return { errors };

  edits.sort((a, b) => a.from - b.from);
  let out = '';
  let k = 0;
  for (const e of edits) {
    for (; k < e.from; k++) out += renameArg(toks[k], isFunction);
    out += e.replacement;
    k = e.to + 1;
  }
  for (; k < toks.length; k++) out += renameArg(toks[k], isFunction);

  if (isFunction && usedArgs.size) {
    const idx = [...usedArgs].sort((a, b) => a - b);
    const prologue = `var ${idx.map((i) => `botArg${i}`).join(', ')}; ` +
      idx.map((i) => `botArg${i} = global.botA${i};`).join(' ') + ' ';
    out = prologue + out;
  }
  // Calls inside the replacements were rewritten from the original argument
  // text, which may itself name argumentN.
  if (isFunction) out = out.replace(/\bargument([0-9]+)\b/g, 'botArg$1');
  return { code: out };
}

function renameArg(tok, isFunction) {
  if (isFunction && tok.type === 'ident' && /^argument[0-9]+$/.test(tok.text)) {
    return 'botArg' + tok.text.slice('argument'.length);
  }
  return tok.text;
}

module.exports = { transpile, tokenize, NAME_RE };
