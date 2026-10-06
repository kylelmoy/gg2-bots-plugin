# Departures: brain (ScriptedBot, population, server plumbing)

- **A bot joins over a loopback socket, through the real handshake**
  (`botJoinStart`/`botJoinService`). gg2-server adds a bot as an
  `IInputSource` directly; the GM8 game has no seam for that, and patching
  the game is off the table for a plugin. The game already gives the host's
  own player a loopback connection (`GameServerCreate`), so a bot is the same
  thing. It joins under a unique tag (`~botN`) and is renamed in the same
  broadcast, after the join, so no client ever draws the tag.
- **Commands land one tick later than in gg2-server.** A bot's client
  commands (team, class, zoom, build, eat, drop, bubble) travel through its
  socket and are read by the next `GameServerBeginStep`. `ScriptedBot`'s zoom
  test would therefore send a second toggle before the first landed, undoing
  it; `botScriptedPollCommands` waits 3 ticks between toggles.
- **Keys are decided at the end of a tick, not at its start.** The GameServer
  End Step hook writes them; the next tick's Begin Step serialises and applies
  them, which is where a person's input is. A Begin Step hook would run after
  `serializeState` and put bots' keys on the wire a tick late. The bot sees
  the world as it is after the tick, which is what gg2-server's poll sees.
- **One slot is always left free** (`botPopulationService`): a bot holds a
  real slot here, and `RESERVE_SLOT` would refuse a person at a full server.
  gg2-server has no slot limit for bots to collide with.
- **The stagger is a join counter**, not the roster slot at the time of
  joining: same purpose (spreading cadences), no dependence on who left.
- **Retarget and Rerole are noticed, not announced** (`botBrainService`): a
  signature of every bot's team and class, and the nav generation, are
  compared each tick. gg2-server calls them from the code that made the
  change; here the change is made by the game, a tick after the request.
- **`Lanes` are never assigned**, as on gg2-server's live server, which never
  derives them either.
- **Bots think at 30 Hz on a 60 fps server**, on virtual ticks only; the
  character applies each decision over two frames. Measured on koth_valley,
  12 bots, 150 s: path blacklisting and stuck counts match 30 fps within the
  run-to-run noise.
