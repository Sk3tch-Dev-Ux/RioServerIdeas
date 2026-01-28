# Server Launch Preparation Guide

## Complete Checklist for Going Live

This guide walks you through launching the DEA vs Cartel server from closed beta through public launch.

---

## PHASE 1: PRE-LAUNCH (Week 1-2)

### 1.1 Discord Setup ✅

**Create Discord Server:**
- [ ] Create new Discord server
- [ ] Set up channels:
  - #announcements (read-only)
  - #rules (rule enforcement)
  - #support (player questions)
  - #suggestions (feature requests)
  - #bug-reports (bug tracker)
  - #staff (admin discussion)
  - #alerts (game alerts via webhook)

**Configure Webhooks:**
```
1. Go to each channel settings
2. Click "Integrations" → "Webhooks"
3. Create webhook, copy URL
4. Update in config.lua:
   Config.Discord.webhooks.majorEvents = 'YOUR_WEBHOOK_URL'
   Config.Discord.webhooks.raids = 'YOUR_WEBHOOK_URL'
   Config.Discord.webhooks.territoryWars = 'YOUR_WEBHOOK_URL'
   Config.Discord.webhooks.feedback = 'YOUR_WEBHOOK_URL'
   Config.Discord.webhooks.errors = 'YOUR_WEBHOOK_URL'
```

**Configure Roles:**
- [ ] Create roles: Admin, Moderator, Staff, Member, Whitelist
- [ ] Set up permissions for each role
- [ ] Create welcome message with rules and links

### 1.2 Server Configuration ✅

**Update Server Info:**
```lua
Config.ServerInfo = {
    name = 'Your Server Name',
    website = 'https://your-website.com',
    discord = 'https://discord.gg/your-invite',
    maxPlayers = 32,  -- Adjust based on hardware
    version = '1.0.0'
}
```

**Configure Launch Status:**
```lua
Config.ServerInfo.launchStatus = 'CLOSED_BETA'  -- Until ready for public
Config.ServerInfo.whitelist = true              -- For closed beta
Config.ServerInfo.estimatedLaunchDate = '2024-XX-XX'
```

**Set Feature Flags:**
```lua
Config.ServerInfo.features = {
    drugProduction = true,      -- Enable production
    turf_wars = true,          -- Enable territory wars
    auctions = true,           -- Enable auction house
    progressionSystem = true,  -- Enable progression
    deaMechanics = true       -- Enable DEA
}
```

### 1.3 Rules & Guidelines ✅

**Review Default Rules:**
- [ ] Edit server rules in `Config.ServerRules.rules`
- [ ] Add server-specific rules (hours, RP requirements, etc.)
- [ ] Review faction guidelines in `Config.ServerRules.guidelines`

**Example Custom Rules to Add:**
```lua
{
    title = 'Server Hours',
    description = 'Server resets daily at 6 AM EST. Save your progress!',
    severity = 'MEDIUM'
},
{
    title = 'RP Quality',
    description = 'Maintain high-quality roleplay at all times.',
    severity = 'HIGH'
},
{
    title = 'No Hacking',
    description = 'Exploiting game mechanics will result in ban.',
    severity = 'HIGH'
}
```

### 1.4 Whitelist Setup

**Manual Whitelist Method:**
```lua
-- Create server/whitelist.lua
local Whitelist = {
    ['citizen123'] = true,  -- CitizenID
    ['citizen456'] = true
}

function IsPlayerWhitelisted(citizenId)
    return Whitelist[citizenId] ~= nil
end

-- In server/main.lua, add check on player join
```

**Or use Discord Whitelist Bot:**
- [ ] Set up Discord bot (Python/Node.js based)
- [ ] Create whitelist management commands
- [ ] Link Discord → game whitelist
- [ ] Document whitelist process

### 1.5 Database Setup

**For Data Persistence:**
```lua
-- If using MySQL/MariaDB:
-- 1. Create database: CREATE DATABASE dea_cartel;
-- 2. Import schema file (if available)
-- 3. Update connection string in server config
-- 4. Test connection before launch

-- Minimal tables needed:
-- - players (citizenid, data)
-- - feedback (id, player, category, text, timestamp)
-- - auctions (history)
-- - raids (history)
```

**For File-Based (Testing Only):**
```lua
-- Use SaveResourceFile() for simple persistence
-- Data stored in resources/dea-cartel/data/
-- Backup daily before production use
```

---

## PHASE 2: CLOSED BETA (Week 2-3)

### 2.1 Beta Testing Setup ✅

**Enable Beta Mode:**
```lua
Config.BetaMode.enabled = true

-- Configure what's in beta:
Config.BetaMode.betaFeatures = {
    auctions = { active = true, startDate = '2024-01-15' },
    turfWars = { active = true, startDate = '2024-01-15' },
    progressionSystem = { active = true, startDate = '2024-01-08' },
    advancedDEA = { active = true, startDate = '2024-01-08' }
}

-- Enable analytics
Config.BetaMode.analytics.trackPlayerActions = true
Config.BetaMode.analytics.trackEconomyEvents = true
Config.BetaMode.analytics.trackBugs = true
```

**Select Beta Testers:**
- [ ] Recruit 10-20 experienced players
- [ ] Mix of different playstyles (cartel, DEA, neutral)
- [ ] Include builders, combat players, and RPers
- [ ] Set expectations: report bugs, provide feedback
- [ ] Consider NDA for early access (optional)

**Set Testing Duration:**
```
Duration: 1-2 weeks
Schedule: Specific times (e.g., Fri-Sun 7-11 PM)
Reset: Daily backup, weekly full wipe if needed
Feedback: Daily debrief calls/Discord discussions
```

### 2.2 Launch Beta Server

**Server Files:**
- [ ] Copy all resource files to server
- [ ] Verify fxmanifest.lua loads all scripts
- [ ] Check console for errors on startup
- [ ] Verify all systems initialized

**Test Checklist:**
```
✓ Server boots without errors
✓ Players can connect
✓ Database/save system works
✓ All menus load correctly
✓ No script timeouts
✓ Memory usage < 150MB
✓ FPS stable > 60
✓ Network events process
✓ Discord webhooks fire
```

**Load Test:**
```
With 1 player:   All systems responsive
With 5 players:  Monitor CPU/memory
With 10 players: Check FPS stability
With 20 players: Full stress test
```

### 2.3 Monitor Beta Performance

**Daily Checks:**
```bash
# Check server logs for errors
# Monitor memory usage over time
# Track event processing speed
# Note any lag or crashes
# Collect player feedback

# In-game console commands:
print(GetResourceMemoryUsage('dea-cartel'))  -- Memory
GetNumberOfThreads()                          -- Threads
```

**Weekly Analysis:**
- [ ] Review collected feedback
- [ ] Identify top balance issues
- [ ] Fix critical bugs
- [ ] Plan adjustments
- [ ] Document changes

---

## PHASE 3: OPEN BETA (Week 3-4)

### 3.1 Transition to Open Beta

**Update Config:**
```lua
Config.ServerInfo.launchStatus = 'OPEN_BETA'
Config.ServerInfo.whitelist = true  -- Keep whitelist for stability

-- Keep analytics active
-- Continue Discord logging
```

**Announce on Discord:**
```
"Open Beta is live! Join us to help test and shape the server.
Apply for whitelist in #whitelist channel.
Report bugs in #bug-reports.
Suggest features in #suggestions."
```

**Whitelist Applications:**
- [ ] Create application form (Google Form or bot command)
- [ ] Set review criteria (active, good standing, etc.)
- [ ] Approve/deny applications daily
- [ ] Add approved players to whitelist

### 3.2 Expanded Testing

**Include:**
- [ ] 30-50 players total
- [ ] Extended testing window (daily/nightly)
- [ ] Public Discord channels
- [ ] Regular feedback surveys
- [ ] Live balance patches

**Balance Monitoring:**
```
Track these metrics:
- Average player wealth (progression)
- Territory ownership changes (PvP health)
- Auction prices (economy health)
- Raid frequency (DEA balance)
- Player retention (engagement)
```

### 3.3 Bug Fixes & Patches

**Hotfix Process:**
1. Bug reported in #bug-reports
2. Admin reproduces issue
3. Developer fixes and tests
4. Patch deployed (server restart)
5. Confirmation in Discord
6. Add to patch notes

**Balance Adjustments:**
```
Weekly patch note example:
"v1.0.1 - Balance Adjustments
- Increased auction item drop chance
- Reduced DEA raid heat threshold by 10%
- Fixed territory bonus not applying
- Improved dashboard performance"
```

---

## PHASE 4: PUBLIC LAUNCH (Week 4+)

### 4.1 Final Launch Prep

**24 Hours Before:**
- [ ] Final performance test with 20+ players
- [ ] Backup database
- [ ] Update website/Discord
- [ ] Brief staff team
- [ ] Prepare announcements
- [ ] Test whitelist removal

**Launch Window:**
- [ ] Schedule during peak player hours
- [ ] Have admins online
- [ ] Monitor server closely
- [ ] Have rollback plan ready

### 4.2 Update Configurations

```lua
Config.ServerInfo.launchStatus = 'LAUNCH'
Config.ServerInfo.whitelist = false  -- Open to public
Config.ServerInfo.maxPlayers = 32    -- Adjust as needed

-- Keep all monitoring systems active
Config.Discord.logging = {
    majorRaids = true,
    territoryConquests = true,
    auctionMilestones = true,
    playerMilestones = true,
    criticalErrors = true,
    playerFeedback = true
}
```

### 4.3 Launch Announcement

**Social Media & Discord:**
```
"🎮 DEA vs CARTEL IS LIVE! 🎮

Build your criminal empire or enforce the law!

Features:
✅ Drug production system
✅ Territory wars
✅ Black market auctions
✅ 4-tier progression
✅ Dynamic DEA mechanics
✅ Team-based gameplay

Join us now! [Server IP]
Discord: [Link]
Rules: [Link]"
```

**In-Game Welcome:**
```lua
-- Add to player spawn
TriggerClientEvent('QBCore:Notify', source, 
    'Welcome to DEA vs Cartel! Type /rules for server rules',
    'primary', 5000)
```

---

## PHASE 5: LIVE OPERATIONS (Week 4+)

### 5.1 Daily Operations

**Morning (Server Reset):**
- [ ] Review overnight logs
- [ ] Check for critical errors
- [ ] Verify economy health
- [ ] Brief team on issues

**During Playtime:**
- [ ] Monitor server performance
- [ ] Respond to support tickets
- [ ] Watch for exploits
- [ ] Engage with community

**Evening (Before Reset):**
- [ ] Backup database
- [ ] Review logs
- [ ] Document issues
- [ ] Plan next day

### 5.2 Weekly Maintenance

**Patch Day (Suggested: Monday):**
```
1. Collect feedback from past week
2. Prioritize balance changes
3. Write patch notes
4. Deploy update with restart
5. Announce changes
6. Monitor for new issues
```

**Patch Priority:**
1. Critical bugs (crashes, exploits)
2. Balance breaking issues
3. Performance problems
4. QoL improvements
5. Feature requests

### 5.3 Community Management

**Discord Management:**
- [ ] Active moderation
- [ ] Respond to support tickets
- [ ] Post announcements
- [ ] Engage in discussion
- [ ] Monthly newsletter

**Player Feedback Loop:**
```
1. Collect via /feedback command
2. Review in #suggestions Discord
3. Discuss with staff
4. Implement popular ideas
5. Announce implemented feedback
```

### 5.4 Performance Monitoring

**Ongoing Metrics:**
```
Daily:
- Memory usage trend
- Crash/error count
- Player satisfaction (feedback)
- Server uptime

Weekly:
- Economy health (wealth distribution)
- Feature usage (auctions, raids, etc.)
- Player retention rate
- Top issues from feedback

Monthly:
- Overall growth/decline
- Revenue (if applicable)
- Strategic adjustments
```

---

## TROUBLESHOOTING LAUNCH ISSUES

### Server Won't Start
```
1. Check for Lua syntax errors: console output
2. Verify all dependencies installed (qb-core, ox_lib, ox_target, ox_inventory)
3. Check fxmanifest.lua script order
4. Look for missing config values
5. Run individual scripts to isolate issue
```

### High Memory Usage
```
1. Check memory over time: GetResourceMemoryUsage()
2. Reduce concurrent operations limit
3. Disable distance rendering if needed
4. Reduce max active auctions
5. Check for memory leaks in loops
```

### Player Connection Issues
```
1. Verify server is accessible (port open)
2. Check player limit not exceeded
3. Verify whitelist working correctly
4. Check Discord webhook URLs
5. Monitor network bandwidth
```

### Economy Broken
```
1. Check player balance logs
2. Verify transaction amounts
3. Audit dealer payouts
4. Check territory bonus calculations
5. Review auction pricing
```

### DEA Too Hard/Easy
```
Adjust in config.lua:
- Config.DEA.heatIncrease (lower = easier)
- Config.DEA.raidProbability (lower = easier)
- Config.DEA.agentCount (lower = easier)
- Config.ProgressionTiers (higher threshold = harder)
```

---

## LAUNCH CHECKLIST (FINAL)

### Infrastructure
- [ ] Server hardware confirmed adequate
- [ ] Network bandwidth sufficient
- [ ] Database operational
- [ ] Backup system active
- [ ] Monitoring tools set up

### Configuration
- [ ] Discord webhooks working
- [ ] Server info updated
- [ ] Rules configured
- [ ] Features enabled
- [ ] Whitelist system working

### Testing
- [ ] All systems tested
- [ ] Performance verified
- [ ] Balance approved
- [ ] No critical bugs
- [ ] Load test passed

### Documentation
- [ ] Rules published
- [ ] Guidelines clear
- [ ] Support docs ready
- [ ] Admin guide complete
- [ ] Player FAQ ready

### Community
- [ ] Discord server ready
- [ ] Staff trained
- [ ] Mods recruited
- [ ] Welcome message posted
- [ ] Launch announcement ready

### Launch Day
- [ ] All systems online
- [ ] Staff standing by
- [ ] Monitoring active
- [ ] Support ready
- [ ] Announcement posted

---

## POST-LAUNCH TIMELINE

**Week 1:** Hotfixes & stabilization
**Week 2-4:** Balance adjustments
**Month 2:** Feature polishing
**Month 3+:** Content expansions

---

## SUPPORT & RESOURCES

**For Help:**
- Check QUICK_START_ENGAGEMENT.md for feature overview
- See OPTIMIZATION_GUIDE.md for performance help
- Review ENGAGEMENT_TESTING.md for testing procedures
- Check code comments in source files

**Important Files:**
- config.lua - All configuration
- LAUNCH_GUIDE.md - This file
- QUICK_START_ENGAGEMENT.md - Quick reference
- SYSTEM_STATUS.md - Current status

---

## SUCCESS METRICS

After 1 Month:
- [ ] 50+ active players
- [ ] <5% crash rate
- [ ] 4.0+ player rating (feedback)
- [ ] Stable 60+ FPS
- [ ] Economy balanced
- [ ] Territory turnover healthy
- [ ] Player retention >40%

---

**Ready to launch? Start with Phase 1 above!**

