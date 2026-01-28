# Deployment & Launch Checklist

## Complete Pre-Launch Verification

Use this checklist to ensure everything is ready for server launch.

---

## SECTION 1: CODE & FILES

### Source Code
- [ ] All .lua files present and valid
- [ ] No syntax errors (test in IDE)
- [ ] No missing `local` declarations (prevent globals)
- [ ] All exports defined correctly
- [ ] All event handlers registered
- [ ] No hardcoded paths (use relative paths)
- [ ] No console.log() calls (use print())
- [ ] No TODO or FIXME comments in code

### Configuration
- [ ] config.lua complete and accurate
- [ ] All Config.* sections present
- [ ] No placeholder values remaining
- [ ] Discord webhook URLs valid
- [ ] Server name and info updated
- [ ] Rules configured
- [ ] Features enabled/disabled as intended
- [ ] Whitelist setup decided (manual/bot/automatic)

### File Structure
- [ ] fxmanifest.lua properly formatted
- [ ] All script files listed in manifest
- [ ] Scripts in correct load order
- [ ] Dependencies declared (qb-core, ox_lib, etc.)
- [ ] Version number set
- [ ] Author/description correct

### Documentation
- [ ] README.md or welcome file present (optional)
- [ ] Comments added to complex functions
- [ ] Config options documented
- [ ] Launch guide reviewed
- [ ] Admin guide created (optional)
- [ ] Player rules clear

---

## SECTION 2: DEPENDENCIES

### Framework
- [ ] QBCore installed and running
- [ ] QBCore database connected
- [ ] QBCore player data accessible

### Libraries
- [ ] ox_lib installed
- [ ] ox_target installed (if using targeting)
- [ ] ox_inventory installed (if using inventory)
- [ ] json library available
- [ ] MySQL/Database driver ready

### Version Compatibility
- [ ] FiveM client version compatible
- [ ] Framework versions match requirements
- [ ] No deprecated native functions used
- [ ] All resources use compatible event names

---

## SECTION 3: DATABASE

### Setup
- [ ] Database created (if using persistent storage)
- [ ] Tables created or auto-initialized
- [ ] Connection string configured
- [ ] Credentials secured (not in public config)
- [ ] Backup system configured

### Testing
- [ ] Test write operation succeeds
- [ ] Test read operation succeeds
- [ ] Data persists across restarts
- [ ] No SQL injection vulnerabilities
- [ ] Performance acceptable (< 100ms queries)

---

## SECTION 4: DISCORD INTEGRATION

### Webhooks
- [ ] Major Events webhook URL set
- [ ] Raids webhook URL set
- [ ] Territory Wars webhook URL set
- [ ] Feedback webhook URL set
- [ ] Errors webhook URL set
- [ ] All URLs tested and working

### Channels
- [ ] #announcements channel exists
- [ ] #rules channel exists
- [ ] #support channel exists
- [ ] #bug-reports channel exists
- [ ] #suggestions channel exists
- [ ] #alerts channel for webhooks exists

### Bot Setup (if applicable)
- [ ] Bot token configured securely
- [ ] Bot has necessary permissions
- [ ] Whitelist bot commands working (if using)
- [ ] Bot role assignments configured

---

## SECTION 5: SYSTEMS VERIFICATION

### Core Features
- [ ] Drug production system working
  - [ ] Grow houses operational
  - [ ] Labs operational
  - [ ] Yield calculation correct
  - [ ] Quality system functional
- [ ] Sales system working
  - [ ] Dealers spawn correctly
  - [ ] Payouts calculated properly
  - [ ] Bulk sales functional
  - [ ] Money laundering works
- [ ] Growth mechanics functional
  - [ ] Plant health tracking
  - [ ] Growth time accurate
  - [ ] Notifications working
  - [ ] Harvest ready alerts
- [ ] DEA mechanics working
  - [ ] Heat system tracking
  - [ ] Raids triggering correctly
  - [ ] Agents spawning properly
  - [ ] Evasion mechanics functional
- [ ] Gang dynamics working
  - [ ] Informant system operational
  - [ ] Bribes calculating correctly
  - [ ] Betrayal mechanics functional
  - [ ] Loyalty tracking accurate
- [ ] Progression system working
  - [ ] Reputation tracking
  - [ ] Tier upgrades firing
  - [ ] Cooldowns enforcing
  - [ ] Multipliers applying
  - [ ] Anti-grind protection active

### Engagement Features
- [ ] Auction house operational
  - [ ] Auctions generating
  - [ ] Bidding working
  - [ ] Item effects applying
  - [ ] Winners receiving items
- [ ] Territory system working
  - [ ] Territories claimable
  - [ ] Bonuses applying
  - [ ] Vulnerability triggering
  - [ ] Turf wars functional
- [ ] Dashboard UI functional
  - [ ] Grow ops dashboard loads
  - [ ] DEA intel dashboard loads
  - [ ] Territory dashboard loads
  - [ ] Auction dashboard loads
  - [ ] Data syncing correctly
- [ ] Rules system working
  - [ ] /rules command works
  - [ ] /guidelines command works
  - [ ] /serverinfo command works
  - [ ] Rules display correctly
- [ ] Feedback system working
  - [ ] /feedback command opens form
  - [ ] Submissions to server
  - [ ] Discord logging
  - [ ] File/database storage

---

## SECTION 6: PERFORMANCE

### Memory
- [ ] Initial memory < 50MB
- [ ] Memory stable over time
- [ ] No memory leaks after 1 hour
- [ ] Cleanup running every 5 minutes
- [ ] Peak usage < 100MB

### CPU
- [ ] Script CPU usage < 10%
- [ ] No frame drops during normal play
- [ ] FPS stays > 60 in populated areas
- [ ] No lag during raids
- [ ] Events processing without backlog

### Network
- [ ] Event frequency optimized
- [ ] Bandwidth usage reasonable
- [ ] No event spam
- [ ] Discord webhooks firing
- [ ] No timeout errors

### Threads
- [ ] Active threads < 20
- [ ] No zombie threads
- [ ] Threads cleanup properly
- [ ] No runaway loops
- [ ] Wait() calls in all loops

---

## SECTION 7: SECURITY

### Validation
- [ ] Server validates all client inputs
- [ ] No client-side validation only
- [ ] Exploit prevention checks present
- [ ] Money transactions secured
- [ ] Item transfers verified

### Credentials
- [ ] No passwords in code
- [ ] No API keys visible
- [ ] Discord webhooks not exposed
- [ ] Database credentials secured
- [ ] Sensitive data server-side only

### Whitelist
- [ ] Whitelist system chosen and ready
- [ ] Admin bypass configured (if needed)
- [ ] Ban system prepared
- [ ] Kick reasons logged
- [ ] Appeal process documented

---

## SECTION 8: TESTING

### Functional Testing
- [ ] All menus open without errors
- [ ] All commands work correctly
- [ ] Events fire on schedule
- [ ] Notifications display properly
- [ ] UI elements responsive

### Balance Testing
- [ ] Drug prices reasonable
- [ ] Dealer payouts fair
- [ ] Auction items valuable
- [ ] Territory bonuses balanced
- [ ] DEA difficulty appropriate
- [ ] Progression pace good

### Edge Cases
- [ ] Handles low player count
- [ ] Handles high player count
- [ ] Recovery from crashes
- [ ] Database disconnection recovery
- [ ] Webhook failure handling

### Load Testing
- [ ] 5 players simultaneously
- [ ] 10 players simultaneously
- [ ] 20 players simultaneously
- [ ] No performance degradation
- [ ] No crashes under load

---

## SECTION 9: DOCUMENTATION

### User Documentation
- [ ] Server rules clear
- [ ] Role guidelines clear
- [ ] How to play guide
- [ ] Feature explanations
- [ ] Command list

### Admin Documentation
- [ ] Admin commands documented
- [ ] Configuration explained
- [ ] Troubleshooting guide
- [ ] Balance adjustment guide
- [ ] Update procedure

### Developer Documentation
- [ ] Code comments present
- [ ] Architecture documented
- [ ] API documented (exports)
- [ ] Event list documented
- [ ] Database schema documented

---

## SECTION 10: LAUNCH PREPARATION

### Communication
- [ ] Discord server created
- [ ] Rules channel posted
- [ ] Welcome message posted
- [ ] Support procedures defined
- [ ] Announcement drafted
- [ ] Social media scheduled (if applicable)

### Team
- [ ] Admins recruited and trained
- [ ] Moderators chosen and trained
- [ ] Support team ready
- [ ] Discord roles assigned
- [ ] On-call rotation planned

### Monitoring
- [ ] Monitoring tools configured
- [ ] Discord alerts enabled
- [ ] Log file location known
- [ ] Backup schedule set
- [ ] Incident response plan

### Schedule
- [ ] Launch date set
- [ ] Time agreed with team
- [ ] Announcement schedule
- [ ] Maintenance window planned
- [ ] Rollback plan ready

---

## SECTION 11: FINAL CHECKS (24 HOURS BEFORE)

### Server
- [ ] Server boots cleanly
- [ ] No console errors
- [ ] All systems initialized
- [ ] Memory stable
- [ ] CPU usage normal

### Database
- [ ] Connection working
- [ ] Data clean
- [ ] Backups current
- [ ] Restore tested
- [ ] Performance good

### Configuration
- [ ] All values correct
- [ ] Webhooks verified
- [ ] Whitelist ready
- [ ] Server info current
- [ ] Rules published

### Team
- [ ] All admins online
- [ ] Discord mods active
- [ ] Support ready
- [ ] Communication working
- [ ] Plan reviewed

---

## SECTION 12: LAUNCH DAY

### Pre-Launch (1 hour before)
- [ ] Server offline (if needed)
- [ ] Final backup created
- [ ] All systems checked
- [ ] Team briefed
- [ ] Announcement posted

### During Launch
- [ ] Monitor console for errors
- [ ] Watch Discord for issues
- [ ] Check player count growing
- [ ] Monitor performance metrics
- [ ] Respond to support tickets

### Post-Launch (First hour)
- [ ] Verify players can join
- [ ] Verify features working
- [ ] Monitor for crashes
- [ ] Gather initial feedback
- [ ] Address critical issues

### Post-Launch (First day)
- [ ] Monitor for exploits
- [ ] Balance check
- [ ] Performance check
- [ ] Bug report triage
- [ ] Plan hotfixes if needed

---

## SECTION 13: KNOWN ISSUES & WORKAROUNDS

### Issue: High Memory Usage
**Solution:** Reduce Config.Performance limits, disable distance rendering

### Issue: Server Won't Start
**Solution:** Check fxmanifest.lua, verify dependencies, check console errors

### Issue: Database Connection Failed
**Solution:** Verify credentials, check connection string, restart database service

### Issue: Players Can't Connect
**Solution:** Check whitelist, verify server accessible, check port forwarding

### Issue: Discord Webhooks Not Firing
**Solution:** Verify URLs correct, check bot permissions, test webhook manually

---

## SECTION 14: SUCCESS CRITERIA

### Technical Success
- [x] No critical bugs in first 24 hours
- [x] Server stays online for full session
- [x] Performance remains stable
- [x] All systems functional
- [x] No exploits discovered

### Community Success
- [x] Players joining smoothly
- [x] Support requests answered quickly
- [x] Rules being followed
- [x] Positive feedback received
- [x] Player retention > 20%

### Strategic Success
- [x] Launch goals achieved
- [x] Player base growing
- [x] Community engagement high
- [x] Update plan in place
- [x] Long-term vision clear

---

## SIGN-OFF

### Developer
- Name: _______________
- Date: _______________
- Signature: _______________

### Admin/Owner
- Name: _______________
- Date: _______________
- Signature: _______________

### IT/Infrastructure
- Name: _______________
- Date: _______________
- Signature: _______________

---

## NOTES

```
Use this space for launch-specific notes:
- Server IP/Port: _______________
- Launch Date/Time: _______________
- Emergency Contact: _______________
- Rollback Plan: _______________
- First Patch ETA: _______________
```

---

**Once all items checked, you're ready to launch!**

Good luck and enjoy the server! 🚀

