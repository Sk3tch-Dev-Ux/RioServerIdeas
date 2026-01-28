# Progression System Integration Checklist

## Configuration Setup ✅

### Tier System
- [x] 4 progression tiers defined (Street Soldier → Lieutenant → Boss → Kingpin)
- [x] Reputation thresholds set (0, 150, 400, 750, 1000)
- [x] Tier limits configured (operations, plants, bribes, informants)
- [x] Economy multipliers per tier
- [x] Tier unlock notifications enabled

### Reputation System
- [x] Reputation gain events configured (+2 to +100 per activity)
- [x] Reputation loss events configured (-20 to -100 per activity)
- [x] Per-reputation bonuses configured (0.1% dealer bonus, 0.2% heat reduction, 0.5% bribery bonus)

### Economy Balance
- [x] Supply/demand system configured (±30% fluctuation)
- [x] Price caps set for all drugs (marijuana, cocaine, meth)
- [x] Laundering fee progression (15% → 8% by amount)
- [x] Bulk sale quantity bonuses (5% → 20%)
- [x] Growth yield scaling by tier (0.8x → 1.5x)
- [x] Growth time scaling by tier (1.2x slower → 0.6x faster)

### Cooldown System
- [x] All action cooldowns configured (plant, harvest, sales, laundering, etc.)
- [x] Tier-specific cooldown reductions enabled
- [x] Anti-grind diminishing returns configured
- [x] Activity tracking window (1 hour)
- [x] Daily earnings caps set
- [x] Daily activity caps configured

### DEA Difficulty Scaling
- [x] Raid frequency scaling (0.5x → 1.5x)
- [x] Raid severity scaling (weaker → elite agents)
- [x] Heat gain/decay scaling per tier
- [x] Raid threshold scaling (70 → 95 heat)
- [x] Agent count scaling (1-2 → 4-8)
- [x] Preparation time scaling (2 min → 15 min)
- [x] Seizure rate scaling (50% → 100%)

---

## Server-Side Implementation ✅

### File: server/progression.lua

**Core Functions:**
- [x] `GetPlayerProgression(source)` - Create/retrieve player progression data
- [x] `GetPlayerTier(source)` - Get current tier based on reputation
- [x] `AddReputation(source, amount, reason)` - Add/subtract reputation + trigger tier ups
- [x] `CanPerformAction(source, actionType)` - Check cooldown status
- [x] `SetActionCooldown(source, actionType)` - Apply cooldown with tier scaling
- [x] `ApplyDiminishingReturns(source, activityType, baseReward)` - Grind protection
- [x] `CheckEarningsCap(source, amount)` - Daily earnings limit
- [x] `CheckActivityCap(source, category, type)` - Daily activity limits
- [x] `CanAccessFeature(source, feature)` - Tier-based feature gating
- [x] `GetTierLimits(source, limitType)` - Get operation/plant/bribe limits
- [x] `ApplyEconomyMultiplier(source, baseAmount, multiplierType)` - Economy scaling
- [x] `ApplyDetectionChance(source, baseChance)` - Detection risk scaling
- [x] `GetDEADifficultyMultiplier(source, type)` - DEA raid scaling
- [x] `GetDEAHeatScaling(source, type)` - Heat system scaling
- [x] `GetRaidDifficulty(source)` - Get raid parameters
- [x] `GetYieldMultiplier(source)` - Plant yield scaling
- [x] `GetGrowthTimeMultiplier(source)` - Growth speed scaling
- [x] `UpdateMarketDemand()` - Supply/demand updates
- [x] `GetAdjustedPrice(drugType, basePrice)` - Apply market multipliers
- [x] `GetLaunderingFee(amount)` - Progressive fee calculation
- [x] `CanLaunderAmount(source, amount)` - Tier/amount validation
- [x] `SyncProgressionToClient(source)` - Update client with progression data

**Background Threads:**
- [x] Cooldown cleanup thread (every 60 seconds)
- [x] Market demand update thread (every 5 minutes)

**Events:**
- [x] `dea-cartel:server:requestProgression` - Client requests progression sync

---

## Client-Side Implementation ✅

### File: client/progression.lua

**Core Tables:**
- [x] `ClientProgression` - Tracks reputation, tier, perks, limits
- [x] `ClientMarketDemand` - Tracks drug demand multipliers

**Display Functions:**
- [x] `DisplayProgressionUI()` - Show progression status
- [x] `ShowProgressionMenu()` - Full progression details menu
- [x] `ShowTierUnlockDetails(tierData)` - Celebrate tier ups with details
- [x] `AddProgressionMenuOption()` - Integration with main menu

**Helper Functions:**
- [x] `GetClientTier()` - Get current tier locally
- [x] `GetClientReputation()` - Get reputation locally
- [x] `CanAccessFeature(feature)` - Check if feature unlocked
- [x] `GetTierLimit(limitType)` - Get tier-based limits
- [x] `GetMarketMultiplier(drugType)` - Get demand multiplier

**Events:**
- [x] `dea-cartel:client:updateReputation` - Reputation change notification
- [x] `dea-cartel:client:tierUnlock` - Tier up celebration
- [x] `dea-cartel:client:updateProgression` - Full progression sync
- [x] `dea-cartel:client:cooldownWarning` - Cooldown notifications
- [x] `dea-cartel:client:diminishingReturnsWarning` - Grind protection feedback
- [x] `dea-cartel:client:earningsCapWarning` - Daily cap warnings
- [x] `dea-cartel:client:updateMarketDemand` - Market price changes

---

## Integration with Existing Systems ✅

### Sales System (server/sales.lua)

**Updates to LaunderMoney():**
- [x] Check cooldown before laundering
- [x] Verify tier can launder (Lieutenant+)
- [x] Apply tier maximum laundering amount
- [x] Check daily earnings cap
- [x] Check daily activity cap
- [x] Apply progression fee scaling
- [x] Apply diminishing returns
- [x] Apply detection risk scaling
- [x] Reward reputation for success
- [x] Set cooldown after completion

### Growth System (Prepared)

**To integrate in next PR:**
- [ ] Apply yield multiplier based on tier in `HarvestPlant()`
- [ ] Apply growth time multiplier in `TickPlantGrowth()`
- [ ] Check cooldowns for plant/harvest actions
- [ ] Apply diminishing returns to harvests
- [ ] Reward reputation for successful harvests

### DEA System (Prepared)

**To integrate in next PR:**
- [ ] Apply raid frequency scaling in raid triggers
- [ ] Apply raid severity in agent selection
- [ ] Scale heat gain/decay by tier in `AddPlayerHeat()`
- [ ] Apply heat threshold scaling
- [ ] Scale seizure rates by tier

### Dynamics System (Prepared)

**To integrate in next PR:**
- [ ] Apply tier limits to bribery and informant systems
- [ ] Check cooldowns for bribery actions
- [ ] Apply tier cost multipliers to defenses/informants
- [ ] Reward reputation for successful evasion

---

## Configuration References ✅

### Config.ProgressionTiers
```
✅ street_soldier (0-150 reputation)
✅ lieutenant (150-400 reputation)
✅ boss (400-750 reputation)
✅ kingpin (750-1000 reputation)
```

Each tier includes:
- [x] level, minReputation, maxReputation
- [x] label, description, icon
- [x] maxOperations, maxUpgrades, maxPlants, maxBribes, maxInformants
- [x] canLaunder flag
- [x] dealerPayoutMultiplier, bribeCostMultiplier, upgradesCostMultiplier, heatAccumulation
- [x] maxLaunderingAmount, maxBulkSaleQuantity, blackMarketDetectionChance
- [x] perks list

### Config.Reputation
- [x] startingReputation (0)
- [x] minReputation, maxReputation (0-1000)
- [x] events with gain/loss values
- [x] perReputation benefits

### Config.EconomyBalance
- [x] supplyDemand settings
- [x] priceCaps for all drug types
- [x] launderingBalance with fees and risk
- [x] bulkSaleBalance with quantity bonuses and risk
- [x] growthBalance with yield and time scaling

### Config.CooldownSystem
- [x] operationCooldowns (plant, harvest, sales, laundering, bribery, raiding)
- [x] byTier overrides for each action
- [x] diminishingReturns configuration
- [x] activityCaps with daily limits

### Config.DEADifficultyScaling
- [x] scalingFactors per tier
- [x] heatScaling per tier
- [x] raidAdjustments per tier

---

## Files Modified/Created

### New Files
1. [x] `/server/progression.lua` (479 lines) - Server progression system
2. [x] `/client/progression.lua` (403 lines) - Client progression UI
3. [x] `/PROGRESSION_GUIDE.md` - Complete progression documentation
4. [x] `/PROGRESSION_INTEGRATION.md` - This checklist

### Modified Files
1. [x] `/config.lua` - Added progression, economy, cooldown, DEA scaling configs
2. [x] `/fxmanifest.lua` - Added progression scripts to manifest
3. [x] `/server/sales.lua` - Integrated cooldowns, tier limits, economy multipliers, reputation

---

## Testing Checklist

### Unit Tests
- [ ] Reputation system (add, subtract, tier detection)
- [ ] Cooldown tracking (set, check, cleanup)
- [ ] Diminishing returns (counter increments, multipliers apply)
- [ ] Earnings caps (tracking, reset on new day)
- [ ] Economy multipliers (tier scaling applied correctly)
- [ ] DEA difficulty (raid parameters scale properly)

### Integration Tests
- [ ] New player starts as Street Soldier with 0 reputation
- [ ] Laundering applies cooldowns and economy scaling
- [ ] Tier up notification triggers at 150 reputation
- [ ] Tier limits enforced (can't create 3 operations as street soldier)
- [ ] Reputation gain from laundering success
- [ ] Daily earnings cap prevents infinite farming
- [ ] Diminishing returns kicks in after 5 drug sales
- [ ] Market demand updates every 5 minutes
- [ ] DEA raid parameters scale with player tier

### Manual Testing
- [ ] Client receives tier unlock notification
- [ ] Progression menu displays tier info and perks
- [ ] Cooldown warnings show remaining time
- [ ] Market demand changes show in prices
- [ ] Grind protection messages appear

---

## Known Limitations & Future Work

### Current Limitations
1. Progression only integrated into laundering system (first pass)
2. DEA system uses old heat scaling (will upgrade next PR)
3. Growth system uses old yield system (will upgrade next PR)
4. Dynamics system not yet using tier limits (will upgrade next PR)

### Next Integration Tasks
1. **Growth System**: Apply yield/time multipliers, cooldowns, reputation rewards
2. **DEA System**: Scale raid frequency/severity/heat/seizures by tier
3. **Dynamics System**: Apply tier limits and costs, reputation rewards
4. **Client Integration**: Add progression display to all menus
5. **Admin Tools**: Commands to view/reset player progression

### Potential Enhancements
- Prestige system (reset with bonus at max reputation)
- Perks that unlock special operations
- Faction-specific tier paths
- Reputation decay over time (lose reputation if inactive)
- Territory control scaling based on tier
- Special legendary items at kingpin tier

---

## Configuration Balance Guide

All values are tunable in `/config.lua`. Adjust if:

**Too easy to tier up?**
- Increase reputation thresholds (e.g., 150 → 250 for Lieutenant)
- Decrease reputation gains for activities
- Increase daily activity caps

**Too hard to tier up?**
- Decrease reputation thresholds
- Increase reputation gains
- Decrease daily activity caps

**Farming too easy?**
- Increase diminishing returns penalties
- Decrease daily earnings cap
- Shorten cooldown by tier reductions

**Too grindy?**
- Increase reputation gains
- Decrease cooldowns
- Increase daily caps

**DEA too weak?**
- Increase raid frequency multiplier at higher tiers
- Increase raid severity
- Decrease heat decay

**DEA too strong?**
- Decrease raid frequency
- Decrease heat gains
- Increase heat decay at higher tiers

---

## Status: READY FOR INTEGRATION

✅ Configuration complete  
✅ Server system implemented  
✅ Client UI implemented  
✅ First system (laundering) integrated  
✅ Documentation complete  
✅ Next: Integrate with growth, DEA, dynamics systems  

**Ready to proceed with full system integration and testing.**
