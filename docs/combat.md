# combat

The combat half of a bot: `BotCombat`, `BotCombatState`, `BotTargeting`,
`BotVisibility`, `BotAim`, `BotReflex`, `BotSuppress`, `BotStab`, `BotMines`,
`BotAlly`, `BotClassKeys`, `BotClassProfile`, `BotSkill` and `BotStep` from
gg2-server's `GG2.Bots`. Source in `src/fn/combat/`, constants in
`src/constants/combat.txt`, differences from the C# in
`docs/departures/combat.md`.

Identity throughout: a "slot" is a **Player instance**; `char` is that
player's `object` (`-1` when dead). Class is `player.class` (`CLASS_*`), team
`player.team` (`TEAM_RED`/`TEAM_BLUE`).

## Per-bot fields (on the Player; all set by `botCombatInit`)

`BotCombatState`:

| field | C# | what |
|---|---|---|
| `botCombatTargetExists` | `Target.Exists` | has a target |
| `botCombatTargetKind` | `Target.Kind` | `BOT_TARGET_KIND_NONE/CHARACTER/SENTRY/GENERATOR` |
| `botCombatTargetSlot` | `Target.Slot` | the target's **Player** for a character; the **Sentry** / **Generator** instance otherwise; `noone` with no target |
| `botCombatTargetX`, `botCombatTargetY` | `Target.X/Y` | where it is: a character's origin (chest), a map object's box centre; refreshed every tick |
| `botCombatTargetVisible` | `Target.Visible` | as last reported (acquisition, then the perceive cadence) |
| `botCombatTargetAt` | `TargetAt` | `global.botTick` the target was picked |
| `botCombatLastSeenAt` | `LastSeenAt` | last tick it was actually seen |
| `botCombatVisible` | `Visible` | the LIVE sightline flag (perceive cadence) |
| `botCombatPotshot` | `Potshot` | acquired at the widened potshot radius |
| `botCombatAimDir` | `AimDir` | where the aim points (degrees, [0, 360)) |
| `botCombatAimWant` | `AimWant` | where it is slewing to |
| `botCombatAimX`, `botCombatAimY` | `AimX/Y` | the point solved for (aim distance) |
| `botCombatPerceiveAt`, `botCombatAimAt` | `PerceiveAt`, `AimAt` | next refresh ticks |
| `botCombatAimSubjectKind/Slot/X/Y/Visible` | `AimSubject` | what the snapshot was of |
| `botCombatSeeX/SeeY/SeeVx/SeeVy` | `SeeX...` | the snapshot |
| `botCombatHoldFire` | `HoldFire` | this aim interval's hold-fire roll |
| `botCombatCloakAt` | `CloakAt` | last spy cloak toggle |
| `botCombatAttackKeys` | `AttackKeys` | the keys asked for last tick |
| `botCombatStagger` | `Stagger` | phase into the shared cadences (a join counter) |
| `botCombatAlly` | `Ally` | the Player this medic beams, or `noone` (`BotAlly.None`) |
| `botCombatSuppressNode`, `botCombatSuppressAt` | `SuppressNode`, `SuppressAt` | suppression spot (`BOT_SUPPRESS_NO_SPOT`) and its clock |

`BotSkill` (from `global.botDifficulty` via `botSkillForTier`; rewrite with
`botSkillFor(player, skill)` / `botSkillForTier(player, tier)`):
`botSkillSkill`, `botSkillAcquireTicks`, `botSkillFireDelayTicks`,
`botSkillPerceiveTicks`, `botSkillAimInterval`, `botSkillTurnRate`,
`botSkillAimErrorDeg`, `botSkillAimConeDeg`, `botSkillMoveErrorMultiplier`,
`botSkillHoldFireChance`, `botSkillSplashAim`, `botSkillLeadMode`
(`BOT_LEAD_*`), `botSkillReflexTicks`, `botSkillReflexMissChance`,
`botSkillPolicyAimErrorDeg`.

## Functions

Results beyond `global.botRet` are named in each file's header.

| function | C# |
|---|---|
| `botCombatInit(player)`, `botCombatFree(player)` | state construction (Free has nothing to free) |
| `botCombatStep(player, char)` | `BotCombat.Step`: keys in `global.botRet`, `global.botRetAim`, `global.botRetAimDist` |
| `botCombatDropTarget(player)` | `BotCombatState.DropTarget` |
| `botCombatSpread(err, cone, moveMult, moving, sinceSeen, dist)` | `BotCombat.Spread` |
| `botCombatKeepOrDropTarget`, `botCombatLookForOne`, `botCombatStillWorthShootingAt`, `botCombatPerceive`, `botCombatSolveAim`, `botCombatSlew` | `BotCombat`'s private steps |
| `botTargetingClassRange(class)`, `botTargetingClassMinBand(class)` | |
| `botTargetingUnderFire(player)`, `botTargetingAttentionRange(player)` | |
| `botTargetingEnemyWithin(player, range)` | |
| `botTargetingAngleDelta(a, b)` | |
| `botTargetingFind(player, range)` | `global.botRet` = Exists; `global.botRetKind/Slot/X/Y/Visible` |
| `botVisibilityCanSee(viewerChar, subjectChar)` | |
| `botAimBallistics(char)` | speed in `global.botRet`, `global.botRetGravity`, `global.botRetDrift` |
| `botAimSolve(char, tx, ty, tvx, tvy, leadMode, floorY)` | |
| `botAimLead(sx, sy, tx, ty, tvx, tvy, speed, gravity, drift, floorY)` | |
| `botAimFallPredict(y, vy, t, floorY)`, `botAimFloorUnder(x, y)` | `BOT_AIM_NO_FLOOR` = `NoFloor` |
| `botReflexInBlastBeam(...)`, `botReflexIncomingProjectile(player, minTravel, reflexTicks, missChance)`, `botReflexRocketDodge(player, reflexTicks, missChance)` | |
| `botReflexNoticed(proj, player, reflexTicks, missChance)`, `botReflexRoll(proj, player)`, `botReflexTravelledFrom(proj)` | private there |
| `botSuppressSpot(char, lastX, lastY, foeTeam)`, `botSuppressCentre(node)` | Centre returns `global.botRetX/Y` |
| `botStabWindow(char, targetChar)` | |
| `botMinesArmed(player)` | |
| `botAllyFind(player, range, skipFollowers)`, `botAllyStillValid(player, ally)` | Player or `noone` |
| `botClassKeysFor(player, char, distance, subjectIsAlly)` | `BotClassKeys.For` (SpyKeys inlined) |
| `botClassProfilePotshots/Heals/Splash/SpecialIsFire/AirJump/Follows/Suppresses/AimError/AimSettle/CloseIn/SpotMode/DefendEvery/SpotHigh(class)` | |
| `botSkillFor(player, skill)`, `botSkillForTier(player, tier)`, `botSkillIsTier(tier)`, `botSkillLerp(skill, v0, v1, v2, v3)` | |
| `botStepSafe(char, dir)` | `BotStep.Safe` |

## Calls into other modules

- `navGraphSnapObjective(x, y)` (nav): node in `global.botRet`, stand y in
  `global.botRetGoalY`. Used by `botAimFloorUnder` and `botSuppressSpot`.
- `navGraphGatePassable(gate, team, hasIntel, setupGatesClosed)` (nav),
  only for an edge whose gate is not `NAV_GATE_NONE`.
- `botArcClear(char, aimDegrees, speed, gravity, targetX, targetY)` (path):
  `BotArc.Clear` without its collision-world argument.
- Reads `global.botNavReady`, `global.botNavNodes`, `global.botNavEdges`,
  `global.botNavEdgeStart` directly, and `global.botTick`,
  `global.botDifficulty`.

## Game variables read

Character: `x y hspeed vspeed image_xscale hp maxHp team player intel cloak
stabbing onground zoomed aimDirection currentWeapon timeUnscathed
lastDamageDealer lastDamageSource left/right/top/bottom_bound_offset`.
Player: `object team class botIsBot` (the last is the plugin's own).
Weapons: `Flamethrower.readyToBlast/ammoCount`, `Medigun.uberReady`,
`Revolver.readyToStab`, `Rifle.t/chargeTime`. Projectiles: `Rocket`, `Mine`,
`Flare` `team ownerPlayer hspeed vspeed speed`, `Rocket.lastknownx/y`. `Sentry`
`team hp ownerPlayer bbox_*`; `Generator` (`GeneratorRed`/`Blue`) `team hp
bbox_*`. `global.DAMAGE_SOURCE_SENTRYTURRET`.
