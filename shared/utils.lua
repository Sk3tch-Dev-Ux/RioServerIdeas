Utils = {}

-- Format money
function Utils.formatMoney(amount)
    return '$' .. tostring(math.floor(amount)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

-- Calculate quality based on supplies and random factor
function Utils.calculateQuality(supplyQuality, random)
    local quality = (supplyQuality or 1.0) * (0.8 + random * 0.4)
    return math.max(Config.Quality.minQuality, math.min(Config.Quality.maxQuality, quality))
end

-- Calculate yield based on type, quality, and supplies
function Utils.calculateYield(productionType, quality, supplyBonus)
    local prodConfig = Config.ProductionTypes[productionType]
    if not prodConfig then return 0 end
    
    local baseYield = prodConfig.baseYield
    local qualityFactor = quality or 1.0
    local supplyFactor = supplyBonus or 1.0
    
    return math.floor(baseYield * qualityFactor * supplyFactor)
end

-- Get total setup cost for operation
function Utils.getSetupCost(productionType)
    return Config.ProductionTypes[productionType].setupCost
end

-- Get supply cost for batch
function Utils.getSupplyCost(productionType)
    local prodConfig = Config.ProductionTypes[productionType]
    local totalCost = 0
    
    for supplyName, supplyData in pairs(prodConfig.supplies) do
        totalCost = totalCost + (supplyData.cost * supplyData.perBatch)
    end
    
    return totalCost
end

-- Check if player has items
function Utils.hasItems(source, items)
    local QBCore = exports['qb-core']:GetCoreObject()
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false end
    
    for itemName, itemAmount in pairs(items) do
        if not player.Functions.HasItem(itemName, itemAmount) then
            return false
        end
    end
    
    return true
end

-- Remove items from player
function Utils.removeItems(source, items)
    local QBCore = exports['qb-core']:GetCoreObject()
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false end
    
    for itemName, itemAmount in pairs(items) do
        player.Functions.RemoveItem(itemName, itemAmount)
    end
    
    return true
end

-- Calculate bulk sale payout
function Utils.calculateBulkPayout(drugType, amount, baseReward)
    local multiplier = Config.BulkPaymentMultipliers[drugType] or 1.0
    local bulkBonus = 1.0 + (amount / 1000) * 0.1  -- 10% bonus per 1000g
    return math.floor(baseReward * multiplier * bulkBonus)
end

-- Calculate laundering clean money output
function Utils.calculateCleanMoney(dirtyAmount, conversionRate)
    return math.floor(dirtyAmount * conversionRate)
end

-- Calculate laundering fee
function Utils.calculateLaunderingFee(dirtyAmount, conversionRate)
    local cleanMoney = Utils.calculateCleanMoney(dirtyAmount, conversionRate)
    return dirtyAmount - cleanMoney
end

-- Get current market price for drug with time multiplier
function Utils.getTimePricedDrug(drugType, basePrice)
    local hour = tonumber(os.date('%H'))
    local multiplier = 1.0
    
    for _, period in pairs(Config.TimePricing) do
        if hour >= period.start and hour < period.endTime then
            multiplier = period.multiplier
            break
        end
    end
    
    return math.floor(basePrice * multiplier)
end

-- Calculate bribery cost with modifiers
function Utils.calculateBribeCost(agentGrade, evidenceCount, reputationLevel)
    local rankMultiplier = Config.Bribery.rankMultipliers[agentGrade + 1] or 1.0
    local evidenceMultiplier = 1.0 + (evidenceCount * Config.Bribery.evidenceMultiplier)
    local baseCost = Config.Bribery.baseCost * rankMultiplier * evidenceMultiplier
    
    -- Reputation discount
    if reputationLevel and reputationLevel > 50 then
        baseCost = baseCost * Config.Reputation.benefits.highReputation.briberyDiscount
    elseif reputationLevel and reputationLevel < -50 then
        baseCost = baseCost * Config.Reputation.benefits.lowReputation.briberyPrice
    end
    
    return math.floor(baseCost)
end

-- Calculate hideout detection chance
function Utils.calculateHideoutDetection(securityLevel, playerReputation)
    local baseChance = 0.3
    local securityReduction = securityLevel * 0.05  -- 5% per security level
    local repBonus = 0
    
    if playerReputation then
        if playerReputation > 50 then
            repBonus = -0.1  -- 10% harder to find
        elseif playerReputation < -50 then
            repBonus = 0.2  -- 20% easier to find
        end
    end
    
    return math.max(0.05, baseChance - securityReduction + repBonus)
end

-- Calculate raid survival chance based on defenses
function Utils.calculateRaidSurvival(defenseCount, raidType, hideoutSecurityLevel)
    local baseChance = 0.3
    local defenseBonus = defenseCount * 0.1  -- 10% per defense
    local raidTypeModifier = 0
    
    if raidType == 'standard' then
        raidTypeModifier = 0.2
    elseif raidType == 'swat' then
        raidTypeModifier = -0.3
    elseif raidType == 'sting' then
        raidTypeModifier = 0.1
    end
    
    return math.min(0.95, baseChance + defenseBonus + raidTypeModifier + (hideoutSecurityLevel * 0.05))
end
