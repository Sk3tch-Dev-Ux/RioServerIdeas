# Player Progression & Economy System Guide

## Overview

The DEA vs Cartel game features a **4-tier reputation system** with progressive unlocks, economy balancing, anti-grind mechanics, and DEA difficulty scaling. Players advance from Street Soldier → Lieutenant → Boss → Kingpin by earning reputation.

---

## PROGRESSION TIERS

### Tier 1: Street Soldier (0-150 Reputation)
**Description:** Fresh recruit, limited operations

**Limits:**
- Max 2 active operations
- Max 1 upgrade per operation
- Max 10 plants per grow house
- Max 1 bribe (agent)
- Max 1 informant
- Cannot launder money yet

**Economy Multipliers:**
- Dealer payout: 85% market price
- Bribery cost: 120% normal cost
- Upgrades cost: 110% normal cost
- Heat accumulation: 120% (more heat gain)

**Special:** Black market detection 35% higher, limited bulk sales (250g max)

---

### Tier 2: Lieutenant (150-400 Reputation)
**Description:** Experienced operator, expanded operations

**Limits:**
- Max 4 active operations
- Max 2 upgrades per operation
- Max 20 plants per grow house
- Max 2 bribes
- Max 2 informants
- **CAN launder money** (max $25k per transaction)

**Economy Multipliers:**
- Dealer payout: 92% market price
- Bribery cost: Normal (100%)
- Upgrades cost: Normal (100%)
- Heat accumulation: Normal (100%)

**Special:** Unlocks laundering, better detection chances

---

### Tier 3: Boss (400-750 Reputation)
**Description:** Cartel leader, full operation control

**Limits:**
- Max 6 active operations
- Max 3 upgrades per operation
- Max 30 plants per grow house
- Max 4 bribes
- Max 3 informants
- Launder up to $100k per transaction

**Economy Multipliers:**
- Dealer payout: 100% market price (full value)
- Bribery cost: 85% (15% discount)
- Upgrades cost: 90% (10% discount)
- Heat accumulation: 85% (20% less heat)

**Special:** Better yields (125%), faster growth, improved detection evasion

---

### Tier 4: Kingpin (750-1000 Reputation)
**Description:** Untouchable criminal overlord

**Limits:**
- Max 10 active operations
- Max 4 upgrades per operation
- Max 50 plants per grow house
- Max 6 bribes
- Max 5 informants
- Launder up to $500k per transaction

**Economy Multipliers:**
- Dealer payout: 115% market price (above market)
- Bribery cost: 70% (30% discount)
- Upgrades cost: 75% (25% discount)
- Heat accumulation: 60% (40% less heat)

**Special Perks:**
- Best yields (150%)
- Raid immunity window (30 seconds after raid warning)
- Max 1 raid per week
- Fastest growth (40% faster)
- Elite perks unlock

---

## REPUTATION SYSTEM

### How to Gain Reputation

```
Drug Sale:              +2 per gram sold
Laundering:             +5 per $1,000 laundered
Bulk Sale Success:      +25 per successful delivery
Raid Evasion:           +50
Agent Bribed:           +10
Informant Betrayal Avenged: +100
Hideout Defended:       +35
```

### How to Lose Reputation

```
Captured by DEA:        -100
Informant Betrayal:     -50
Operation Raided:       -20
Laundering Detected:    -30
```

### Reputation Bonuses (All Tiers)

Per reputation point:
- Dealer payout bonus: +0.1%
- Heat reduction: -0.2% per point
- Bribery success bonus: +0.5% per point

**Example:** At 400 reputation, you get +40% dealer bonus, -80% heat reduction, +200% bribery success

---

## ECONOMY BALANCING

### Market Supply & Demand

- Updates every 5 minutes
- Prices fluctuate ±30% based on demand
- Price caps prevent farming:

```
Marijuana:
  Street dealer: $50-100/g
  Black market: $80-150/g

Cocaine:
  Street dealer: $200-350/g
  Black market: $300-500/g

Methamphetamine:
  Street dealer: $150-300/g
  Black market: $250-400/g
```

### Laundering Economy

**Fee Structure (by transaction amount):**
```
Under $10k:    15% fee (85% clean)
$10k-$50k:     12% fee (88% clean)
$50k-$100k:    10% fee (90% clean)
Over $100k:     8% fee (92% clean)
```

**Tier Limits:**
- Street Soldier: Cannot launder
- Lieutenant: Max $25k per transaction
- Boss: Max $100k per transaction
- Kingpin: Max $500k per transaction

### Bulk Sale Scaling

**Quantity Bonuses (price per gram increases with volume):**
```
500g+:   +5% bonus
1000g+:  +10% bonus
2000g+:  +15% bonus
5000g+:  +20% bonus
```

**Detection Risk by Quantity:**
```
Under 500g:    15% detection
Under 1000g:   25% detection
Under 2000g:   40% detection
Over 2000g:    60% detection
```

### Growth Yield Scaling

**Yield Multipliers by Tier:**
```
Street Soldier:  0.80x (80% yield)
Lieutenant:      1.00x (normal)
Boss:            1.25x (25% more)
Kingpin:         1.50x (50% more)
```

**Growth Speed by Tier:**
```
Street Soldier:  1.20x slower (20% longer)
Lieutenant:      1.00x (normal)
Boss:            0.80x faster (20% faster)
Kingpin:         0.60x much faster (40% faster)
```

---

## COOLDOWN & ANTI-GRIND SYSTEM

### Action Cooldowns (Tier-Dependent)

All cooldowns are shorter at higher tiers:

```
Plant Seed:
  Street Soldier: 30s
  Lieutenant: 20s
  Boss: 10s
  Kingpin: 5s

Harvest Plant:
  Street Soldier: 60s
  Lieutenant: 45s
  Boss: 30s
  Kingpin: 15s

Black Market Sale:
  Street Soldier: 120s (2 min)
  Lieutenant: 90s (1.5 min)
  Boss: 60s (1 min)
  Kingpin: 30s

Bulk Sale:
  Street Soldier: 600s (10 min)
  Lieutenant: 480s (8 min)
  Boss: 300s (5 min)
  Kingpin: 180s (3 min)

Laundering:
  Street Soldier: N/A
  Lieutenant: 180s (3 min)
  Boss: 90s (1.5 min)
  Kingpin: 45s

Bribery:
  Street Soldier: 900s (15 min)
  Lieutenant: 720s (12 min)
  Boss: 600s (10 min)
  Kingpin: 300s (5 min)
```

### Diminishing Returns (Grind Protection)

Repeating the same activity in a 1-hour window triggers penalties:

**Drug Sales:**
```
After 5 sales in 1 hour:   80% returns
After 10 sales in 1 hour:  60% returns
After 15 sales in 1 hour:  40% returns
```

**Bulk Sales:**
```
After 3 sales in 1 hour:   85% returns
After 5 sales in 1 hour:   65% returns
After 7 sales in 1 hour:   40% returns
```

**Laundering:**
```
After 5 transactions:      75% returns
After 10 transactions:     50% returns
After 15 transactions:     25% returns
```

**Planting:**
```
After 20 plants:           90% returns
After 40 plants:           70% returns
After 60 plants:           40% returns
```

### Daily Activity Caps

**Max Earnings Per 24 Hours:**
```
Street Soldier:  $500k
Lieutenant:      $1m
Boss:            $2.5m
Kingpin:         $5m
```

**Max Operations Per 24 Hours:**
```
Planting:
  Street Soldier: 10
  Lieutenant: 20
  Boss: 50
  Kingpin: 100

Drug Sales:
  Street Soldier: 5
  Lieutenant: 10
  Boss: 20
  Kingpin: 50

Bulk Sales:
  Street Soldier: 1
  Lieutenant: 2
  Boss: 3
  Kingpin: 5
```

---

## DEA DIFFICULTY SCALING

DEA operations scale based on player progression to maintain challenge:

### Raid Frequency Scaling

```
Street Soldier:  0.50x (50% normal frequency)
Lieutenant:      0.80x (80% normal)
Boss:            1.00x (normal)
Kingpin:         1.50x (50% more raids)
```

### Raid Severity Scaling

```
Street Soldier:  0.50x (weaker agents)
Lieutenant:      0.80x (normal)
Boss:            1.00x (normal)
Kingpin:         1.50x (elite agents)
```

### Heat System Scaling

**Heat Gain/Decay:**
```
Street Soldier:
  Gains: +30% (accumulate 30% more heat)
  Decay: -20% slower
  Raid threshold: 70 heat

Lieutenant:
  Gains: Normal
  Decay: Normal
  Raid threshold: 85 heat

Boss:
  Gains: -20% (accumulate 20% less)
  Decay: +20% faster
  Raid threshold: 90 heat

Kingpin:
  Gains: -50% (accumulate 50% less)
  Decay: +50% faster
  Raid threshold: 95 heat
```

### Raid Adjustments

**Minimum & Maximum Agents:**
```
Street Soldier:  1-2 agents
Lieutenant:      2-3 agents
Boss:            3-6 agents
Kingpin:         4-8 agents
```

**Preparation Time:**
```
Street Soldier:  2 minutes
Lieutenant:      5 minutes
Boss:            10 minutes
Kingpin:         15 minutes
```

**Seizure Rate:**
```
Street Soldier:  50% of items seized
Lieutenant:      70% of items seized
Boss:            85% of items seized
Kingpin:         100% (everything seized)
```

---

## INTEGRATION WITH EXISTING SYSTEMS

### Growth System

Cooldowns apply to:
- Planting seeds
- Harvesting plants
- Installing upgrades

Yields scale by tier, growth times scale inversely.

### Sales System

Cooldowns apply to:
- Black market sales (every 2 min minimum)
- Bulk deliveries (every 10 min minimum)
- Laundering transactions (every 3 min minimum)

Economy multipliers affect:
- Dealer payout prices
- Laundering fees
- Detection chances

### DEA System

Heat scaling changes:
- How much heat accumulates from activities
- How fast heat decays
- At what threshold raids trigger

Raid adjustments change:
- Number of agents
- Raid preparation time
- Seizure rates

---

## PROGRESSION FLOW EXAMPLE

**New Player (Street Soldier)**
1. Start with 0 reputation
2. Can plant max 10 plants, own max 2 operations
3. Get only 85% from dealers
4. Heat accumulates 20% faster
5. Cannot launder money
6. 30 second cooldown between planting

↓ **After earning 100 reputation**
- Still Street Soldier
- Same limits and economy

↓ **After earning 150 reputation (TIER UP: Lieutenant)**
- Can now plant 20 plants
- Own 4 operations
- Get 92% from dealers
- Heat accumulates normal
- CAN launder money (max $25k)
- 20 second cooldown between planting
- DEA raids 20% less frequently

↓ **After earning 400 reputation (TIER UP: Boss)**
- Can plant 30 plants
- Own 6 operations
- Get 100% full market price from dealers
- Heat accumulates 20% less
- Launder up to $100k
- Yields increase 25%
- Growth 20% faster
- 10 second cooldown between planting
- DEA raids normal frequency

↓ **After earning 750 reputation (TIER UP: Kingpin)**
- Can plant 50 plants
- Own 10 operations
- Get 115% (above market price) from dealers
- Heat accumulates 40% less
- Launder up to $500k
- Yields increase 50%
- Growth 40% faster
- 5 second cooldown between planting
- Raid immunity window unlocked
- DEA raids 50% more frequently (but you're wealthy enough to handle it)

---

## ECONOMY MANAGEMENT FOR ADMINS

### View Player Progression
```lua
-- Check in-game or via logs
PlayerProgression[playerID].reputation
PlayerProgression[playerID].tier
```

### Reset Player Progression
```lua
PlayerProgression[playerID] = {
    reputation = 0,
    tier = 'street_soldier',
    cooldowns = {},
    activityCounts = {},
    earningsToday = 0,
    lastReset = os.time()
}
```

### Adjust Market Prices
```lua
Config.EconomyBalance.priceCaps[drugType].maxPrice = 200  -- Adjust caps
MarketDemand[drugType] = 1.5  -- Force demand multiplier
```

---

## TESTING PROGRESSION

See TEST_FLOW.md for detailed progression testing steps.

Quick test:
1. Advance reputation to 150 (check tier change)
2. Test tier limits (try planting 21 plants at street soldier = should fail)
3. Check economy multipliers (compare dealer prices)
4. Verify cooldowns work
5. Check DEA difficulty changes

---

## BALANCE NOTES

The system is designed to:
- Reward progression without creating impossible grind
- Prevent farming through cooldowns + diminishing returns
- Scale DEA challenge as player grows stronger
- Create meaningful economic choices at each tier
- Allow new players to earn faster initially
- Challenge kingpins with constant raid threats but wealth to handle it

Adjust Config values if balance feels off.
