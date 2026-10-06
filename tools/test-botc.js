#!/usr/bin/env node
// Tests for botc.js: node tools/test-botc.js
'use strict';
const assert = require('assert');
const { transpile, loadConstants } = require('./botc.js');

const funcs = new Set(['botFoo', 'botBar']);
const constants = new Map();
assert.deepStrictEqual(loadConstants('BOT_X 12 // c\nNAV_Y -0.5\nBOT_H $1F\n', 't', constants), []);
assert.strictEqual(constants.get('NAV_Y'), '(-0.5)');
assert.deepStrictEqual(loadConstants('lower 1\n', 't', new Map()).length, 1);

let failures = 0;
function ok(name, src, expect, opts = {}) {
  const r = transpile(src, 't.gml', funcs, { constants, ...opts });
  try {
    assert.ok(!r.errors, `unexpected errors: ${r.errors}`);
    for (const e of [].concat(expect)) assert.ok(r.code.includes(e), `missing ${JSON.stringify(e)} in\n${r.code}`);
    assert.strictEqual(r.code.split('\n').length, src.split('\n').length, 'line count changed');
  } catch (e) {
    failures++;
    console.error(`FAIL ${name}: ${e.message}`);
  }
}
function bad(name, src, frag, opts = {}) {
  const r = transpile(src, 't.gml', funcs, { constants, ...opts });
  if (!r.errors || !r.errors.some((e) => e.includes(frag))) {
    failures++;
    console.error(`FAIL ${name}: expected error containing ${frag}, got ${JSON.stringify(r.errors || r.code)}`);
  }
}

ok('statement', 'botFoo(1, 2);', 'global.botA0 = (1); global.botA1 = (2); event_perform_object(global.botF_botFoo, ev_other, ev_user0); }');
ok('assign', 'x = botFoo(a);', 'x = global.botRet; }');
ok('assign field', 'if (y) self.v[3, i] = botFoo();', 'self.v[3, i] = global.botRet; }');
ok('assign after if', 'if (a) x = botBar(BOT_X);\nelse botBar(2);', ['global.botA0 = (12)', 'else {']);
ok('multiline keeps lines', 'x = botFoo(1,\n  2);\ny = 1;', 'y = 1;');
ok('return call', 'return botFoo(argument0);', ['botArg0 = global.botA0', 'global.botA0 = (botArg0)', 'exit; }'], { isFunction: true });
ok('return expr', 'return argument1 + 1;', '{ global.botRet = (botArg1 + 1); exit; }', { isFunction: true });
ok('return bare', 'if (a) return;', 'if (a) exit;', { isFunction: true });
ok('constant', 'x = BOT_X * NAV_Y;', 'x = 12 * (-0.5);');
ok('constant in string untouched', 's = "BOT_X";', '"BOT_X"');
ok('case label', 'switch (k) { case 1: botFoo(); break; }', 'case 1: {');
ok('with block', 'with (Player) { botFoo(id); }', 'global.botA0 = (id)');
bad('in condition', 'if (botFoo(1)) x = 1;', 'whole statement');
bad('in expression', 'x = botFoo(1) + 1;', 'whole statement');
bad('nested', 'botFoo(botBar(1));', 'inside the arguments');
bad('plus-assign', 'x += botFoo(1);', 'inside an expression');
bad('argument array', 'x = argument[0];', 'not supported', { isFunction: true });
bad('argument outside fn', 'x = argument0;', 'outside a function');

if (failures) {
  console.error(`${failures} failure(s)`);
  process.exit(1);
}
console.log('test-botc: all passed');
