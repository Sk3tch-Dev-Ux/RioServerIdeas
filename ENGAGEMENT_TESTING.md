# Engagement & Polish Testing Guide

## Overview

This document outlines testing procedures for Black Market Auctions, Turf Wars, Dashboards, and overall performance optimization.

---

## BLACK MARKET AUCTIONS TESTING

### 1. Auction Generation

**Test:** Auctions are created automatically

```
Steps:
1. Start server
2. Wait 60 seconds
3. Check server console for "New auction created" message
4. Confirm max 5 auctions active at once
5. Verify auctions expire after 10 minutes

Success Criteria:
✓ New auction generated every 60 seconds
✓ Message in console confirms auction
✓ Cannot exceed max active auctions
✓ Expired auctions removed automatically
```

**Config to adjust:**
- `Config.BlackMarketAuctions.refreshInterval` - How often to generate
- `Config.BlackMarketAuctions.maxAuctionsActive` - Max concurrent
- `Config.BlackMarketAuctions.auctionDuration` - How long each auction lasts

### 2. Bidding System

**Test:** Players can bid on auctions

```
Steps:
1. Open auction menu (ShowAuctionDashboard)
2. View active auctions
3. Select an auction
4. Place bid higher than current bid + minimum increment
5. Verify bid placement confirmation
6. Have second player place higher bid on same auction
7. Verify first player gets refund notification

Success Criteria:
✓ Bid dialog appears with minimum bid shown
✓ Bid placed successfully on valid amount
✓ Previous bidder refunded automatically
✓ All players see bid update in real-time
✓ Cannot bid if insufficient funds
✓ Cannot bid below minimum increment
```

**Minimum bid increment:** `Config.BlackMarketAuctions.minBidIncrement`

### 3. Auction Completion

**Test:** Winner receives item and is charged

```
Steps:
1. Wait for auction to expire (10 minutes for testing, reduce to 60000ms = 1 min)
2. Verify winner charged correct amount
3. Verify winner can see item in "My Auction Items"
4. Verify winner can use/equip item
5. Verify item effects apply correctly

Success Criteria:
✓ Winner charged from bank account
✓ Item added to winner's inventory
✓ Other bidders refunded
✓ Item can be activated/used
✓ Correct multipliers apply to yields/detection
```

**Adjust for testing:**
```lua
Config.BlackMarketAuctions.auctionDuration = 60000  -- 1 minute for testing
```

### 4. Item Rarity Distribution

**Test:** Auctions have proper rarity distribution

```
Steps:
1. Monitor auction generation over 1 hour
2. Count rare vs epic vs legendary items
3. Verify realistic distribution (common > rare > epic > legendary)
4. Check starting prices scale with rarity
5. Verify item effects are appropriate for rarity

Success Criteria:
✓ Common items appear most frequently
✓ Legendary items appear rarely
✓ Item starting prices aligned with value
✓ Effects justified by rarity tier
```

**Item rarity config:**
```lua
Config.BlackMarketAuctions.rareSeeds  -- Check rarity field
Config.BlackMarketAuctions.rareEquipment  -- Check rarity field
```

### 5. Auction House Economy

**Test:** Auction economy doesn't create infinite money

```
Steps:
1. Check starting price is 60% of base value
2. Commission is 5% of winning bid
3. Calculate: $100k item, starting at $60k, won at $90k = $4.5k commission
4. Verify items are actually valuable (2x yields, etc.)
5. Check player can't flip items for profit easily

Success Criteria:
✓ Starting prices reasonable (60% of base)
✓ Commission charged fairly (5%)
✓ Item effects worth the cost
✓ Money sink, not money printer
✓ Wealthy players benefit but everyone can participate
```

---

## TURF WARS TESTING

### 1. Territory Claiming

**Test:** Players can claim unclaimed territories

```
Steps:
1. Start server (all territories unclaimed)
2. Navigate to territory location
3. Open territory menu
4. Click "Claim Territory"
5. Verify cost deducted from bank
6. Verify territory shows as owned
7. All players see notification

Success Criteria:
✓ Territory claims cost correct amount (varies by territory)
✓ Player bank deducted correctly
✓ Territory ownership synced to all players
✓ Blip color changes to indicate ownership
✓ Claiming player receives reputation bonus
```

**Territory costs:**
```lua
Config.GangTerritories.territories[i].claimCost
```

### 2. Territory Bonuses

**Test:** Territory bonuses apply to owner

```
Steps:
1. Claim territory (e.g., Downtown = dealer payout +15%)
2. Sell drugs to dealer
3. Compare payout to non-controlled territory
4. Verify +15% bonus applied
5. Do same for other bonuses (heat reduction, production speed, etc.)

Success Criteria:
✓ Dealer payout bonus applies (+15% example)
✓ Heat reduction reduces heat gain
✓ Production speed makes operations faster
✓ Detection reduction lowers raid chance
✓ Multiple bonuses stack properly
```

### 3. Territory Vulnerability

**Test:** Territory becomes vulnerable after control period

```
Steps:
1. Claim territory
2. Check vulnerability status (should be false)
3. Wait for defense duration (adjust to 60 seconds for testing)
4. Verify isVulnerable changes to true
5. See "Territory Vulnerable" notification

Success Criteria:
✓ Territory defended for full duration
✓ Status changes to vulnerable automatically
✓ All players notified when vulnerable
✓ Notification appears on map
```

**Adjust for testing:**
```lua
Config.GangTerritories.territories[i].defenseDuration = 60000  -- 1 minute
```

### 4. Turf War Challenge

**Test:** Players can challenge vulnerable territories

```
Steps:
1. Wait for territory to become vulnerable
2. Have player A claim territory
3. Have player B challenge it
4. Verify defender notified immediately
5. Wait for preparation time (3 minutes, adjust to 30000ms = 30s)
6. War resolves automatically

Success Criteria:
✓ Only vulnerable territories can be challenged
✓ Defender gets warning notification
✓ Preparation period is adequate
✓ War resolves after time expires
```

### 5. Turf War Resolution

**Test:** War winner gets territory and bonuses

```
Steps:
1. Initiate challenge with 3+ attackers
2. Have 1 defender show up (minimum 2 required)
3. Prepare to lose (outnumbered)
4. Wait for resolution
5. Verify attackers win and get territory
6. Verify defender notification
7. Check attacker receives bonuses and reputation

Success Criteria:
✓ Attackers outnumbering defenders win
✓ Territory ownership transfers
✓ Winner gets $200k and 150 reputation
✓ Loser notified of defeat
✓ Territory vulnerable again after 1 hour
✓ War can't be challenged again for defense period
```

### 6. Gang Affiliation

**Test:** Gang system tracks territory ownership

```
Steps:
1. Check if players have gang metadata
2. Verify territory shows owner's gang
3. Test gang bonuses affect territory control
4. Check gang vs gang wars (if implemented)

Success Criteria:
✓ Player gang tracked in metadata
✓ Territory displays owner's gang color
✓ Gang bonuses apply to members
✓ Gang rivalries visible on map (optional)
```

---

## DASHBOARD UI TESTING

### 1. Grow Ops Dashboard

**Test:** Dashboard displays accurate grow house status

```
Steps:
1. Open grow ops dashboard
2. Check operation count matches actual operations
3. Verify plant status shows correctly (growing, ready, etc.)
4. Test upgrade status display
5. Check security status alerts
6. Test plant ready notifications

Success Criteria:
✓ Dashboard shows all active operations
✓ Plant health accurate
✓ Growth time remaining correct
✓ Upgrades display with ETA
✓ Alerts trigger at right times
✓ No performance impact when open
```

### 2. DEA Intel Dashboard

**Test:** DEA intel displays accurate threat level

```
Steps:
1. Open DEA intel dashboard
2. Check current heat level matches server
3. Verify raid probability calculated correctly
4. Test heat warning alerts (trigger at heat > 50)
5. Test raid imminent alert (heat > 80)
6. Check raid history displays properly
7. Test heat reduction strategies

Success Criteria:
✓ Heat level displays current heat
✓ Raid probability calculated accurately
✓ Alerts trigger at correct thresholds
✓ Raid history shows recent activity
✓ Heat reduction options available
✓ No lag from opening dashboard
```

### 3. Territory Control Dashboard

**Test:** Territory map shows current control

```
Steps:
1. Open territory control dashboard
2. Verify all territories display
3. Check ownership shown correctly (owned vs unclaimed)
4. Test color coding by gang
5. Click territory to see details
6. Verify bonuses listed
7. Test claim/challenge buttons

Success Criteria:
✓ All territories visible on map
✓ Ownership colors accurate
✓ Territory details show correct info
✓ Claim cost displayed
✓ Challenge button only shows when vulnerable
✓ Bonuses list complete
```

### 4. Auction Dashboard

**Test:** Auction interface shows active auctions

```
Steps:
1. Open auction dashboard
2. View active auctions list
3. Check item names, current bids, time remaining
4. Click auction to bid
5. View owned items
6. Check auction statistics

Success Criteria:
✓ All active auctions visible
✓ Bid amounts current
✓ Time remaining updates
✓ Bid dialog appears correctly
✓ "My Items" shows won auctions
✓ Stats display (active auctions, avg bid, etc.)
```

### 5. Dashboard Performance

**Test:** Dashboards don't cause lag

```
Steps:
1. Open all dashboards
2. Monitor FPS (should stay > 60)
3. Check memory usage doesn't spike
4. Open dashboard with 30+ players nearby
5. Verify no lag spikes

Success Criteria:
✓ FPS stays above 60 with dashboard open
✓ Memory usage < 50MB total
✓ Smooth scrolling through options
✓ No network lag from updates
```

---

## PERFORMANCE TESTING

### 1. Memory Management

**Test:** Memory doesn't leak over time

```
Steps:
1. Note starting memory: print(GetResourceMemoryUsage('dea-cartel'))
2. Play for 30 minutes
3. Check memory every 5 minutes
4. Verify memory stable (not growing)
5. Check after cleanup interval (5 min): should dip slightly
6. Final memory should be similar to start

Success Criteria:
✓ Memory < 100MB at all times
✓ No unbounded growth
✓ Cleanup visible every 5 minutes (small dip)
✓ Stable after cleanup
```

### 2. Thread Management

**Test:** Threads don't exceed limits

```
Steps:
1. Monitor thread count: GetNumberOfThreads()
2. Start multiple operations simultaneously
3. Check thread count stays < 30
4. Run for extended period
5. Verify threads cleaned up

Success Criteria:
✓ Max threads < 30
✓ No zombie threads
✓ Threads cleaned up after operation
```

### 3. Network Bandwidth

**Test:** Network events are batched properly

```
Steps:
1. Use network monitor (Wireshark or game console)
2. Track event frequency
3. Verify batching reduces frequency:
   - Before: 60 events/second
   - After: ~10 events/second
4. Monitor during peak activity (10+ players)
5. Check compression reduces payload

Success Criteria:
✓ Event frequency reduced by 80%+
✓ Network payload compressed
✓ No noticeable lag from networking
```

### 4. DEA Agent Performance

**Test:** DEA operations don't cause lag

```
Steps:
1. Trigger raid manually
2. Spawn 6+ DEA agents
3. Monitor FPS (should stay > 55)
4. Run raid for 10 minutes
5. Have multiple raids happening
6. Check server CPU usage

Success Criteria:
✓ Raid doesn't drop FPS below 55
✓ No lag spike when agents spawn
✓ Multiple raids run smoothly
✓ Server CPU < 40%
```

### 5. Auction House Performance

**Test:** Auction system handles load

```
Steps:
1. Set to max auctions (50)
2. Have 50+ players all bidding
3. Monitor event processing
4. Check bid queue processes smoothly
5. Verify no missed bids

Success Criteria:
✓ All bids processed
✓ No bids lost
✓ Bid queue under 1 second behind
✓ No server crash under load
```

---

## BALANCE TESTING

### 1. Auction Economics

**Check:** Auctions don't create game-breaking wealth

```
Test case:
- Legendary seed worth $50k
- Starts auction at $30k
- Wins at $45k
- Effect: 2x yield = $X extra profit per cycle

Calculate:
- Extra profit per cycle: $X
- Cost to win: $45k
- Break-even cycles: 45000 / X
- Acceptable: 10+ cycles to break even

Success Criteria:
✓ Most items pay off in 10+ operations
✓ Legendary items reward dedication
✓ Prevent farming infinite wealth
```

### 2. Territory Balance

**Check:** Bonuses aren't too powerful

```
Test cases:
1. Dealer payout +15% = $X more per sale
   - Should offset $60k claim cost in ~100 sales
2. Production speed +25% = X minutes saved
   - Verify not game-breaking
3. Heat reduction = Y less heat
   - Shouldn't trivialize DEA threat
4. Detection reduction = -Z%
   - Still challenging

Success Criteria:
✓ Each bonus significant but balanced
✓ Takes time to pay back claim cost
✓ Didn't break progression progression system
✓ Multiple players can benefit from different territories
```

### 3. Progression Economy

**Check:** Auctions/territories don't break progression

```
Test flow:
1. New player: $0, Street Soldier
2. Wins auction for $5k item → 10% yield boost
3. Sells more drugs at +10% yield
4. Earns extra to claim territory for +15% dealer
5. Combined bonuses reach end-game multipliers too fast?

Success Criteria:
✓ Auction items are nice-to-have, not required
✓ Progression still meaningful without them
✓ Can't skip from Street Soldier to Kingpin via auctions
✓ Balancing encourages all systems
```

---

## BALANCE ADJUSTMENT GUIDE

### Too Powerful Auctions?
- Increase starting price multiplier (0.6 → 0.7)
- Increase minimum auction duration (10 min → 15 min)
- Decrease item effect multipliers (2.0 → 1.5)
- Reduce winning payout frequency

### Too Weak Auctions?
- Decrease starting price (0.6 → 0.5)
- Increase item rarity spawn chance
- Increase item effect multipliers
- Reduce commission (5% → 3%)

### Territory Control Too Easy?
- Increase claim cost for powerful territories
- Increase defense duration (1 hour → 2 hours)
- Require more attackers (3 → 5)
- Reduce territory bonus amounts

### Territory Control Too Hard?
- Decrease claim cost
- Reduce defense duration
- Reduce attacker requirements
- Increase territory bonuses

### Performance Issues?
- Reduce max concurrent auctions
- Increase update intervals
- Reduce batch sizes
- Disable distance rendering

---

## BUG TESTING CHECKLIST

### Auctions
- [ ] Auction generates correctly
- [ ] Bid placed successfully
- [ ] Previous bidder refunded
- [ ] Winner receives item
- [ ] Expired auctions removed
- [ ] No duplicate auctions
- [ ] Item effects apply correctly
- [ ] Commission charged properly
- [ ] Bid history tracking
- [ ] Cannot bid as current owner

### Territories
- [ ] Territory claims correctly
- [ ] Bonuses apply to owner
- [ ] Becomes vulnerable on schedule
- [ ] Challenge initiates properly
- [ ] Defender receives warning
- [ ] War resolves correctly
- [ ] Winner receives bonuses
- [ ] Loser notified properly
- [ ] Blips update correctly
- [ ] Gang data synced

### Dashboards
- [ ] Dashboard opens smoothly
- [ ] Data syncs properly
- [ ] Alerts trigger correctly
- [ ] No visual glitches
- [ ] Responsive menu navigation
- [ ] Notifications appear
- [ ] Updates refresh properly
- [ ] Can interact with items
- [ ] No duplicate entries
- [ ] Correct permissions check

### Performance
- [ ] Memory under 100MB
- [ ] Threads under 30
- [ ] No lag spikes
- [ ] FPS stable 60+
- [ ] Events process on time
- [ ] No script errors
- [ ] Clean shutdown
- [ ] No resource leaks
- [ ] Smooth prop spawning
- [ ] Network efficient

---

## FINAL CHECKLIST

### Features Complete
- [ ] Black Market Auctions fully functional
- [ ] Turf Wars system operational
- [ ] Dashboard UI working
- [ ] Territories map updated
- [ ] Performance optimized

### Testing Complete
- [ ] All test cases passed
- [ ] Performance acceptable
- [ ] Balance verified
- [ ] No critical bugs
- [ ] Memory/thread stable

### Polish Complete
- [ ] Notifications clear
- [ ] UI responsive
- [ ] Error messages helpful
- [ ] No console errors
- [ ] Documentation updated

### Ready for Live
- [ ] All systems integrated
- [ ] Testing complete
- [ ] Performance verified
- [ ] Balance approved
- [ ] Team signed off

