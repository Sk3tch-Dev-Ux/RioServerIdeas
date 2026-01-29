# DEA vs Cartel — Single README (Condensed Master Guide)

One consolidated guide covering: Quick Start, Launch & Deployment, Testing, Optimization, Progression, and Live Operations. This file contains the full condensed reference — no external links to separate guides.

## Purpose
- Single source of truth for admins, devs, and testers.
- Short checklists for launch and daily operations; enough detail to act without opening other docs.

## Quick Start (get running)
Prereqs:
- QBCore framework installed and working
- `ox_lib`, `ox_target`, `ox_inventory` (as used) installed
- Database (MySQL/MariaDB) available if persistence required

Steps:
1. Edit `config.lua`: set `Config.ServerInfo.name`, `discord` webhooks, `launchStatus`, `whitelist`, `maxPlayers` and feature flags.
2. Configure DB connection and ensure credentials are not committed.
3. Ensure `fxmanifest.lua` lists all client/server scripts.
4. Start the resource and verify no console errors.

Quick verification commands (server console):
```bash
-- Check resource memory
print(GetResourceMemoryUsage(GetCurrentResourceName()))
-- Verify threads
print(GetNumberOfThreads())
```

## Launch & Deployment — Condensed Checklist
Pre-Launch (days → 1 week):
- Discord: create server channels (#announcements, #rules, #support, #bug-reports, #alerts) and create webhooks.
- Roles: admin/mod/staff/whitelist and permissions.
- Config: remove placeholder values, set `launchStatus = 'CLOSED_BETA'` for private tests.
- Whitelist: prepare manual list or bot integration.
- Database: create DB, import schema, test read/write, configure backups.

Code & Manifest:
- All .lua files present, no syntax errors, exports registered, no hardcoded credentials.
- `fxmanifest.lua` lists files and dependencies (QBCore, ox_lib).

Security:
- Validate server-side all client inputs; never trust client data.
- Remove secrets from config; use environment or server-side injects where possible.

Beta → Open Beta:
- Recruit testers (10–50 depending on phase), collect feedback, run daily/weekly backups.
- Run stepped load tests: 1, 5, 10, 20 players — monitor memory, CPU, FPS, and net events.

24 hours before Launch:
- Final backup, finalize announcements, staff briefed, rollback plan and hotfix process ready.

Launch Day:
- Admins online, monitor console and Discord, confirm players can join, watch telemetry.

Post-Launch (Ops):
- Daily: review logs, backup DB, triage bug reports.
- Weekly: scheduled patch day for balance and fixes.

## Condensed Deployment Checklist (Actionable)
- Code: syntax clean, no TODOs, exports & event handlers present.
- Config: webhooks set, features toggled correctly, server name/version set.
- Dependencies: QBCore + ox_lib + ox_target installed and compatible.
- DB: connection string correct, backup schedule in place, restore tested.
- Discord: test webhooks and bot permissions.
- Performance targets (see below) verified under load.

## Quick Testing (5–30 minutes)
Basic sanity:
- Start server; confirm resource logs appear.
- Open F6 menu: Criminal and DEA menus present.
- Test one flow end-to-end: plant → harvest → sell → launder.
- Verify progress bars appear and complete for actions (planting, harvesting, laundering, auction bid).

DEA checks:
- Drug test flow, deploy drone, initiate raid (grade-protected), make arrest.

Dashboard & Engagement:
- Open dashboards (grow ops, DEA intel, territories, auctions); interact with at least one feature.

Load steps:
- Run players: 1 → 5 → 10 → 20; monitor memory (target <100MB), threads (<30), CPU.

If failures, triage order:
1. Console errors (fix manifest, missing dependencies) 2. DB/connectivity 3. Missing exports/events 4. Permission/key issues.

## Testing Flow (Condensed)
- Resource load and config validation.
- Functional tests (menus, plant/harvest/sell, DEA flows).
- Integration tests (complete criminal journey and DEA journey).
- Stress tests (multiple simultaneous operations and raids).

## Performance & Optimization (Key Points)
Targets:
- Memory: aim < 100MB (dev target <50MB), threads < 30, FPS > 60.

Techniques used (and where to tweak in `config.lua`):
- Distance-based rendering and LOD to reduce client work.
- Batch processing for DB and network syncs (batch sizes / intervals configurable).
- Object pooling for props and entities.
- Rate-limiting event handlers and bid queues for auction spam protection.
- Heat and agent updates throttled (not per frame).

Quick tune knobs:
- `Config.Performance.scriptOptimization.batchInterval`
- `Config.Performance.networkOptimization.syncInterval`
- `Config.BlackMarketAuctions.auctionDuration` and `maxAuctionsActive`

## Progression & Balance (Summary)
- Four tiers: Street Soldier → Lieutenant → Boss → Kingpin.
- Tiers affect limits (operations, plants), cooldowns, fees, and bonuses.
- Reputation gained by actions (sales, laundering, bulk deliveries, raids evaded); arrests and betrayals reduce reputation.
- Anti-grind: diminishing returns and daily caps enforced.

## Operations & Runbook (Daily / Weekly)
Daily:
- Morning: review overnight logs, check backup status, confirm no critical errors.
- During play: monitor performance, respond to Discord support, watch for exploits.
- Before reset: backup DB, document issues.

Weekly:
- Patch day: collect feedback, prioritize fixes/adjustments, deploy during low-traffic window.

Incident response:
1. Reproduce the issue locally or on a staging server.
2. If critical, deploy hotfix and notify Discord with rollback instructions.

## Admin Commands & Shortcuts
- `TriggerEvent('dea-cartel:server:getAuctions')` — force auction generation
- `print(GetResourceMemoryUsage(GetCurrentResourceName()))` — check memory
- Use `Config.ServerInfo.launchStatus` toggles for beta/launch control.

## Troubleshooting Quick Wins
- Resource won't start: check `fxmanifest.lua` load order and missing deps.
- Missing progress bars or dialogs: verify `ox_lib` is installed and up-to-date.
- DB errors: test connection string and credentials, check migration/schema.
- Discord webhooks not firing: test webhook URL via curl/postman and ensure `Config.Discord.webhooks` set.

## Notes
- This README is the single condensed reference — originals remain in the repo for full historical details if needed.
- If you want originals removed or archived into a `docs/legacy/` folder, I can move them.

---
If you'd like this formatted differently (shorter admin page, separate developer appendix, or archived originals moved), tell me which option and I'll update accordingly.
