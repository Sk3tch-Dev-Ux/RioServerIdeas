local QBCore = exports['qb-core']:GetCoreObject()

-- Track player progression data
PlayerProgression = {}  -- { playerID = { reputation, tier, cooldowns, activityCounts } }

-- ========== REPUTATION & TIER MANAGEMENT ==========

function GetPlayerProgression(source)
    if not PlayerProgression[source] then
        PlayerProgression[source] = {
            reputation = Config.Reputation.startingReputation,
            tier = 'street_soldier',
            cooldowns = {},
            activityCounts = {},
            earningsToday = 0,
            lastReset = os.time()
        }
    end
    return PlayerProgression[source]
end

function GetPlayerTier(source)
    local prog = GetPlayerProgression(source)
    local rep = prog.reputation
    
    for tierName, tierData in pairs(Config.ProgressionTiers) do
        if rep >= tierData.minReputation and rep <= tierData.maxReputation then
            return tierName, tierData
        end
    end
    
    return 'street_soldier', Config.ProgressionTiers.street_soldier
end

function AddReputation(source, amount, reason)
    if not PlayerProgression[source] then
        GetPlayerProgression(source)
    end
    
    local prog = PlayerProgression[source]
    local oldRep = prog.reputation
    
    prog.reputation = math.max(
        Config.Reputation.minReputation,
        math.min(Config.Reputation.maxReputation, prog.reputation + amount)
    )
    
    -- Check for tier upgrade
    local oldTier = prog.tier
    local newTier, tierData = GetPlayerTier(source)
    prog.tier = newTier
    
    local player = QBCore.Functions.GetPlayer(source)
    if player then
        if amount > 0 then
            player.Functions.Notify('Reputation +' .. amount .. ' (' .. reason .. ')', 'success', 3000)
        elseif amount < 0 then
            player.Functions.Notify('Reputation ' .. amount .. ' (' .. reason .. ')', 'error', 3000)
        end
        
        if oldTier ~= newTier then
            player.Functions.Notify('TIER UP: ' .. tierData.label .. '!', 'success', 5000)
            TriggerClientEvent('dea-cartel:client:tierUnlock', source, newTier, tierData)
        end
    end
    
    TriggerClientEvent('dea-cartel:client:updateReputation', source, prog.reputation, newTier)
    
    return prog.reputation
end

-- ========== COOLDOWN MANAGEMENT ==========

function CanPerformAction(source, actionType)
    local prog = GetPlayerProgression(source)
    local tierName = prog.tier
    
    if not Config.CooldownSystem.operationCooldowns[actionType] then
        return true, 'Unknown action'
    end
    
    local cooldownConfig = Config.CooldownSystem.operationCooldowns[actionType]
    local baseDuration = cooldownConfig.duration
    
    -- Check tier-specific cooldown
    if cooldownConfig.byTier and cooldownConfig.byTier[tierName] then
        baseDuration = cooldownConfig.byTier[tierName]
    end
    
    -- Check if on cooldown
    if prog.cooldowns[actionType] then
        local remaining = prog.cooldowns[actionType] - os.time()
        if remaining > 0 then
            return false, 'Cooldown active: ' .. math.ceil(remaining / 1000) .. 's'
        end
    end
    
    return true, 'OK'
end

function SetActionCooldown(source, actionType)
    local prog = GetPlayerProgression(source)
    local cooldownConfig = Config.CooldownSystem.operationCooldowns[actionType]
    
    if not cooldownConfig then return end
    
    local baseDuration = cooldownConfig.duration
    if cooldownConfig.byTier and cooldownConfig.byTier[prog.tier] then
        baseDuration = cooldownConfig.byTier[prog.tier]
    end
    
    prog.cooldowns[actionType] = os.time() + (baseDuration / 1000)
end

-- ========== ANTI-GRIND SYSTEMS ==========

function ApplyDiminishingReturns(source, activityType, baseReward)
    if not Config.CooldownSystem.diminishingReturns.enabled then
        return baseReward
    end
    
    local prog = GetPlayerProgression(source)
    
    if not prog.activityCounts[activityType] then
        prog.activityCounts[activityType] = {
            count = 0,
            startTime = os.time(),
            total = 0
        }
    end
    
    local activity = prog.activityCounts[activityType]
    local now = os.time()
    local trackingWindow = Config.CooldownSystem.diminishingReturns.trackingWindow / 1000
    
    -- Reset counter if outside tracking window
    if (now - activity.startTime) > trackingWindow then
        activity.count = 0
        activity.startTime = now
    end
    
    activity.count = activity.count + 1
    
    -- Get diminishing returns config
    local returnConfig = Config.CooldownSystem.diminishingReturns[activityType .. 'Returns']
    if not returnConfig then
        return baseReward
    end
    
    -- Find applicable multiplier
    local multiplier = 1.0
    for _, threshold in ipairs(returnConfig.thresholds) do
        if activity.count >= threshold.count then
            multiplier = threshold.multiplier
        end
    end
    
    local adjustedReward = math.floor(baseReward * multiplier)
    
    if multiplier < 1.0 then
        local player = QBCore.Functions.GetPlayer(source)
        if player then
            player.Functions.Notify('Diminishing returns: ' .. string.format('%.0f%%', multiplier * 100), 'warning', 2000)
        end
    end
    
    return adjustedReward
end

function CheckEarningsCap(source, amount)
    local prog = GetPlayerProgression(source)
    local tierName = prog.tier
    
    -- Reset daily earnings if new day
    local currentTime = os.time()
    if (currentTime - prog.lastReset) > 86400 then
        prog.earningsToday = 0
        prog.lastReset = currentTime
    end
    
    local dailyCap = Config.CooldownSystem.activityCaps.maxEarningsPerDay[tierName]
    
    if prog.earningsToday + amount > dailyCap then
        local remaining = dailyCap - prog.earningsToday
        return false, 'Daily earnings cap reached. Remaining: ' .. Utils.formatMoney(remaining)
    end
    
    prog.earningsToday = prog.earningsToday + amount
    return true, 'OK'
end

function CheckActivityCap(source, activityCategory, activityType)
    local prog = GetPlayerProgression(source)
    local tierName = prog.tier
    
    -- Reset activity counts if new day
    local currentTime = os.time()
    if (currentTime - prog.lastReset) > 86400 then
        prog.activityCounts = {}
    end
    
    if not prog.activityCounts[activityCategory] then
        prog.activityCounts[activityCategory] = { count = 0, lastTime = 0 }
    end
    
    local count = prog.activityCounts[activityCategory].count
    local capConfig = Config.CooldownSystem.activityCaps.maxOperationsPerDay[activityCategory]
    
    if not capConfig then
        return true, 'OK'
    end
    
    local cap = capConfig[tierName] or 10
    
    if count >= cap then
        return false, 'Daily ' .. activityCategory .. ' cap reached (' .. cap .. ')'
    end
    
    prog.activityCounts[activityCategory].count = count + 1
    return true, 'OK'
end

-- ========== TIER UNLOCK CHECKING ==========

function CanAccessFeature(source, feature)
    local tierName = GetPlayerTier(source)
    local tier = Config.ProgressionTiers[tierName]
    
    if feature == 'laundering' then
        return tier.canLaunder
    elseif feature == 'bulk_sales' then
        return true  -- Available to all
    end
    
    return true
end

function GetTierLimits(source, limitType)
    local tierName = GetPlayerTier(source)
    local tier = Config.ProgressionTiers[tierName]
    
    if limitType == 'max_operations' then
        return tier.maxOperations
    elseif limitType == 'max_upgrades' then
        return tier.maxUpgrades
    elseif limitType == 'max_plants' then
        return tier.maxPlants
    elseif limitType == 'max_bribes' then
        return tier.maxBribes
    elseif limitType == 'max_informants' then
        return tier.maxInformants
    elseif limitType == 'max_laundering' then
        return tier.maxLaunderingAmount
    elseif limitType == 'max_bulk_sale' then
        return tier.maxBulkSaleQuantity
    end
    
    return 0
end

-- ========== ECONOMY MULTIPLIER APPLICATION ==========

function ApplyEconomyMultiplier(source, baseAmount, multiplierType)
    local tierName = GetPlayerTier(source)
    local tier = Config.ProgressionTiers[tierName]
    
    local multiplier = 1.0
    
    if multiplierType == 'dealer_payout' then
        multiplier = tier.dealerPayoutMultiplier
    elseif multiplierType == 'bribe_cost' then
        multiplier = tier.bribeCostMultiplier
    elseif multiplierType == 'upgrade_cost' then
        multiplier = tier.upgradesCostMultiplier
    elseif multiplierType == 'heat_accumulation' then
        multiplier = tier.heatAccumulation
    end
    
    -- Apply reputation bonus
    local prog = GetPlayerProgression(source)
    local repBonus = prog.reputation * Config.Reputation.benefits.perReputation[multiplierType .. 'Bonus']
    
    return math.floor(baseAmount * multiplier * (1 + (repBonus or 0)))
end

function ApplyDetectionChance(source, baseChance)
    local tierName = GetPlayerTier(source)
    local tier = Config.ProgressionTiers[tierName]
    
    local adjustedChance = baseChance + tier.blackMarketDetectionChance
    return math.max(0, math.min(1, adjustedChance))
end

-- ========== DEA DIFFICULTY SCALING ==========

function GetDEADifficultyMultiplier(source, difficultyType)
    local tierName = GetPlayerTier(source)
    local scaling = Config.DEADifficultyScaling.scalingFactors[tierName]
    
    if difficultyType == 'raid_frequency' then
        return scaling.raidFrequency
    elseif difficultyType == 'raid_severity' then
        return scaling.raidSeverity
    elseif difficultyType == 'agent_skill' then
        return scaling.agentSkill
    elseif difficultyType == 'detection_bonus' then
        return scaling.detectionBonus
    end
    
    return 1.0
end

function GetDEAHeatScaling(source, scalingType)
    local tierName = GetPlayerTier(source)
    local scaling = Config.DEADifficultyScaling.heatScaling[tierName]
    
    if scalingType == 'gains' then
        return scaling.gainsMultiplier
    elseif scalingType == 'decay' then
        return scaling.decayMultiplier
    elseif scalingType == 'raid_threshold' then
        return scaling.raidThreshold
    end
    
    return 1.0
end

function GetRaidDifficulty(source)
    local tierName = GetPlayerTier(source)
    return Config.DEADifficultyScaling.raidAdjustments[tierName]
end

-- ========== GROWTH YIELD SCALING ==========

function GetYieldMultiplier(source)
    local tierName = GetPlayerTier(source)
    return Config.EconomyBalance.growthBalance.yieldScaling[tierName] or 1.0
end

function GetGrowthTimeMultiplier(source)
    local tierName = GetPlayerTier(source)
    return Config.EconomyBalance.growthBalance.growthTimeScaling[tierName] or 1.0
end

-- ========== SUPPLY/DEMAND SYSTEM ==========

MarketDemand = {
    marijuana = 1.0,
    cocaine = 1.0,
    methamphetamine = 1.0,
    lastUpdate = os.time()
}

function UpdateMarketDemand()
    if not Config.EconomyBalance.supplyDemand.enabled then return end
    
    local now = os.time()
    if (now - MarketDemand.lastUpdate) < (Config.EconomyBalance.supplyDemand.updateInterval / 1000) then
        return
    end
    
    -- Simple random demand fluctuation
    for drugType, _ in pairs(MarketDemand) do
        if drugType ~= 'lastUpdate' then
            local variation = (math.random() - 0.5) * Config.EconomyBalance.supplyDemand.demandFluctuation
            MarketDemand[drugType] = math.max(0.5, math.min(2.0, 1.0 + variation))
        end
    end
    
    MarketDemand.lastUpdate = now
    
    -- Broadcast to all clients
    TriggerClientEvent('dea-cartel:client:updateMarketDemand', -1, MarketDemand)
end

function GetAdjustedPrice(drugType, basePrice)
    UpdateMarketDemand()
    
    local demandMultiplier = MarketDemand[drugType] or 1.0
    local adjustedPrice = basePrice * demandMultiplier
    
    -- Apply price caps
    local caps = Config.EconomyBalance.priceCaps[drugType]
    if caps then
        adjustedPrice = math.max(caps.minPrice, math.min(caps.maxPrice, adjustedPrice))
    end
    
    return math.floor(adjustedPrice)
end

-- ========== LAUNDERING BALANCE ==========

function GetLaunderingFee(amount)
    local fee = 0.15  -- Default 15%
    
    for _, tier in ipairs(Config.EconomyBalance.launderingBalance.conversionFeeProgression) do
        if amount < tier.threshold then
            fee = tier.fee
            break
        end
    end
    
    return fee
end

function CanLaunderAmount(source, amount)
    local tierName = GetPlayerTier(source)
    local tier = Config.ProgressionTiers[tierName]
    
    if not tier.canLaunder then
        return false, 'Your tier cannot launder money'
    end
    
    if amount < Config.EconomyBalance.launderingBalance.minimumTransaction then
        return false, 'Minimum transaction: ' .. Utils.formatMoney(Config.EconomyBalance.launderingBalance.minimumTransaction)
    end
    
    if amount > tier.maxLaunderingAmount then
        return false, 'Maximum transaction: ' .. Utils.formatMoney(tier.maxLaunderingAmount)
    end
    
    return true, 'OK'
end

-- ========== SYNC PROGRESSION TO CLIENT ==========

function SyncProgressionToClient(source)
    local prog = GetPlayerProgression(source)
    local tierName = prog.tier
    local tier = Config.ProgressionTiers[tierName]
    
    TriggerClientEvent('dea-cartel:client:updateProgression', source, {
        reputation = prog.reputation,
        tier = tierName,
        tierData = tier,
        perks = tier.perks,
        limits = {
            maxOperations = tier.maxOperations,
            maxPlants = tier.maxPlants,
            maxBribes = tier.maxBribes,
            maxInformants = tier.maxInformants,
            maxLaundering = tier.maxLaunderingAmount,
            maxBulkSale = tier.maxBulkSaleQuantity
        }
    })
end

-- ========== EVENTS ==========

RegisterNetEvent('dea-cartel:server:requestProgression', function()
    SyncProgressionToClient(source)
end)

-- Cleanup cooldowns every minute
CreateThread(function()
    while true do
        Wait(60000)  -- 1 minute
        
        for playerID, prog in pairs(PlayerProgression) do
            -- Clean up old cooldowns
            for action, expireTime in pairs(prog.cooldowns) do
                if expireTime < os.time() then
                    prog.cooldowns[action] = nil
                end
            end
        end
    end
end)

-- Update market demand every 5 minutes
CreateThread(function()
    while true do
        Wait(300000)  -- 5 minutes
        UpdateMarketDemand()
    end
end)

print('^2[DEA-Cartel] ^7Player progression system initialized^0')
