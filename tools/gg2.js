#!/usr/bin/env node
//=============================================================================
// gg2.js - call one gg2 MCP tool from the shell.
//
//   node tools/gg2.js <tool> '<json arguments>'
//   node tools/gg2.js gg2_evalx '{"instance":"client1","expr":"global.chatHello"}'
//
// For sessions that do not have the gg2 MCP server attached. Each call is its
// own bridge client and disconnects when it exits, so do not run it while the
// control panel or an MCP session holds the same game (the agent tools' guide,
// "The loop").
//=============================================================================

const mcp = require('D:/Code/gg2-agent/tools/gg2-mcp-server.js');

async function main() {
  const [tool, json] = process.argv.slice(2);
  if (!tool) {
    console.error("usage: node tools/gg2.js <tool> '<json arguments>'");
    process.exit(2);
  }
  const args = json ? JSON.parse(json) : {};
  let failed = false;
  try {
    const r = await mcp.callTool(tool, args);
    const parts = Array.isArray(r) ? r : (r && r.content) || [];
    for (const p of parts) {
      if (p.type === 'text') console.log(p.text);
      else console.log(`[${p.type} omitted]`);
    }
    if (!parts.length) console.log(typeof r === 'string' ? r : JSON.stringify(r));
    failed = !!(r && r.isError);
  } catch (e) {
    console.error(e && e.stack ? e.stack : String(e));
    failed = true;
  }
  if (mcp.disconnectAll) mcp.disconnectAll();
  process.exit(failed ? 1 : 0);
}

main();
