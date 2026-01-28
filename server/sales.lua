local QBCore = exports['qb-core']:GetCoreObject()

-- Track laundering operations
LaunderingOperations = {}  -- { businessID = { transactions = {}, totalLaundered = 0, suspicion = 0 } }

-- Track black market vans
BlackMarketVans = {}  -- { vanID = { active = false, startTime = nil, riskLevel = 0 } }

-- Track surveillance alerts
SurveillanceAlerts = {}  -- { playerID = { level = 0, lastAlert = 0, detections = 0 } }

-- Initialize laundering businesses
for _, business in ipairs(Config.LaunderingBusinesses) do
    LaunderingOperations[business.id] = {
        id = business.id,
        name = business.name,
        transactions = {},
        totalLaundered = 0,
        capacity = business.capacity,
        suspicion = 0,
        lastTransaction = 0,
        raidRisk = 0
    }
end

-- Launder money at a business
function LaunderMoney(source, businessID, amount)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then
        return { success = false, message = 'Player not found' }
    end
    
    -- Check progression cooldown
    local canAct, cooldownMsg = CanPerformAction(source, 'launderingTransaction')
    if not canAct then
        return { success = false, message = cooldownMsg }
    end
    
    -- Check tier can access feature
    if not CanAccessFeature(source, 'laundering') then
        return { success = false, message = 'Your rank cannot launder money. Advance to Lieutenant.' }
    end
    
    -- Find business
    local business = nil
    for _, b in ipairs(Config.LaunderingBusinesses) do
        if b.id == businessID then
            business = b
            break
        end
    end
    
    if not business then
        return { success = false, message = 'Business not found' }
    end
    
    local op = LaunderingOperations[businessID]
    if not op then
        return { success = false, message = 'Business not operational' }
    end
    
    -- Validate amount with tier limits
    local tierMaxLaunder = GetTierLimits(source, 'max_laundering')
    if tierMaxLaunder == 0 then
        return { success = false, message = 'Your tier cannot launder money' }
    end
    
    if amount < Config.EconomyBalance.launderingBalance.minimumTransaction then
        return { success = false, message = 'Minimum: ' .. Utils.formatMoney(Config.EconomyBalance.launderingBalance.minimumTransaction) }
    end
    
    if amount > tierMaxLaunder then
        return { success = false, message = 'Maximum: ' .. Utils.formatMoney(tierMaxLaunder) }
    end
    
    if amount > business.maxTransaction then
        return { success = false, message = 'Business max: ' .. Utils.formatMoney(business.maxTransaction) }
    end
    
    -- Check daily earnings cap
    local canEarn, earningsMsg = CheckEarningsCap(source, amount)
    if not canEarn then
        return { success = false, message = earningsMsg }
    end
    
    -- Check activity cap
    local canActivity, activityMsg = CheckActivityCap(source, 'launderingTransactions', 'laundering')
    if not canActivity then
        return { success = false, message = activityMsg }
    end
    
    -- Check if player has dirty cash
    if player.PlayerData.money.cash < amount then
        return { success = false, message = 'You don\'t have ' .. Utils.formatMoney(amount) .. ' cash' }
    end
    
    -- Check business capacity
    if op.capacity.current + amount > op.capacity.max then
        return { success = false, message = 'Business at capacity. Try again later.' }
    end
    
    -- Remove dirty money
    player.Functions.RemoveMoney('cash', amount)
    
    -- Calculate clean money with progression scaling
    local feeRate = GetLaunderingFee(amount)
    local baseCleaned = math.floor(amount * (1.0 - feeRate))
    
    -- Apply diminishing returns if active
    local cleanMoney = ApplyDiminishingReturns(source, 'launderingReturns', baseCleaned)
    
    -- Add clean money to bank
    player.Functions.AddMoney('bank', cleanMoney)
    
    -- Update business capacity
    op.capacity.current = op.capacity.current + amount
    
    -- Track transaction
    table.insert(op.transactions, {
        playerID = source,
        playerName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
        amount = amount,
        cleaned = cleanMoney,
        timestamp = os.time()
    })
    
    op.totalLaundered = op.totalLaundered + cleanMoney
    op.lastTransaction = os.time()
    
    -- Calculate risk with progression scaling
    local baseRisk = CalculateLaunderingRisk(op, business, source)
    
    -- Apply tier detection bonus/penalty
    local detectionChance = ApplyDetectionChance(source, baseRisk)
    
    player.Functions.Notify('Laundered ' .. Utils.formatMoney(cleanMoney) .. ' (Fee: ' .. string.format('%.0f%%', feeRate * 100) .. ', Risk: ' .. string.format('%.0f%%', detectionChance * 100) .. ')', 'success', 5000)
    
    -- Check for detection with adjusted risk
    CheckSurveillanceDetection(source, businessID, detectionChance)
    
    -- Reward reputation for successful laundering
    local reputationGain = math.floor(cleanMoney / 100000) * Config.Reputation.events.launderingSuccess
    if reputationGain > 0 then
        AddReputation(source, reputationGain, 'Successful money laundering')
    end
    
    -- Set cooldown
    SetActionCooldown(source, 'launderingTransaction')
    
    return {
        success = true,
        dirtyAmount = amount,
        cleanAmount = cleanMoney,
        fee = amount - cleanMoney,
        risk = detectionChance
    }
end

-- Calculate risk for laundering operation
function CalculateLaunderingRisk(operation, business, playerID)
    local baseRisk = business.riskBase * Config.Surveillance.launderingMultiplier
    
    -- Increase risk based on consecutive transactions
    local recentTransactions = 0
    local now = os.time()
    for _, trans in ipairs(operation.transactions) do
        if (now - trans.timestamp) * 1000 < Config.Surveillance.transactionWindow then
            recentTransactions = recentTransactions + 1
        end
    end
    
    if recentTransactions > Config.Surveillance.maxConsecutiveTransactions then
        baseRisk = baseRisk + (Config.Surveillance.consecutiveLaunderingRisk * (recentTransactions - Config.Surveillance.maxConsecutiveTransactions))
    end
    
    -- Business capacity affects risk (full = more visible)
    local capacityRatio = operation.capacity.current / operation.capacity.max
    baseRisk = baseRisk * (1.0 + capacityRatio * 0.5)
    
    return math.min(baseRisk, 0.95)  -- Cap at 95%
end

-- Check for surveillance detection and potential raid
function CheckSurveillanceDetection(playerID, businessID, risk)
    if not Config.Surveillance.enabled then return end
    
    local detectionChance = Config.Surveillance.baseDetectionChance * risk
    
    if math.random() < detectionChance then
        TriggerSurveillanceAlert(playerID, businessID)
    end
end

-- Trigger surveillance alert on player
function TriggerSurveillanceAlert(playerID, businessID)
    if not SurveillanceAlerts[playerID] then
        SurveillanceAlerts[playerID] = {
            level = 0,
            lastAlert = os.time(),
            detections = 0,
            businessIDs = {}
        }
    end
    
    local alert = SurveillanceAlerts[playerID]
    alert.detections = alert.detections + 1
    alert.lastAlert = os.time()
    
    if not alert.businessIDs[businessID] then
        alert.businessIDs[businessID] = 0
    end
    alert.businessIDs[businessID] = alert.businessIDs[businessID] + 1
    
    -- Escalate surveillance level
    alert.level = math.floor(alert.detections / 3)
    
    local player = QBCore.Functions.GetPlayer(playerID)
    if player then
        local message = 'DEA surveillance detected at business!'
        if alert.level > 2 then
            message = 'CRITICAL: Heavy surveillance - Raid imminent!'
        end
        
        player.Functions.Notify(message, 'error', 5000)
    end
    
    -- Potential raid trigger
    if alert.detections >= 5 then
        ScheduleRaid(playerID, businessID)
    end
    
    TriggerClientEvent('dea-cartel:client:surveilanceAlert', playerID, alert.level)
end

-- Schedule a raid on a business
function ScheduleRaid(playerID, businessID)
    local business = nil
    for _, b in ipairs(Config.LaunderingBusinesses) do
        if b.id == businessID then
            business = b
            break
        end
    end
    
    if not business then return end
    
    local player = QBCore.Functions.GetPlayer(playerID)
    if not player then return end
    
    local op = LaunderingOperations[businessID]
    
    -- Seize money at business
    local seized = math.floor(op.capacity.current * Config.Surveillance.detectionConsequences.moneySeizure)
    op.capacity.current = op.capacity.current - seized
    
    -- Give wanted level
    TriggerClientEvent('dea-cartel:client:setWanted', playerID, Config.WantedSystem.launderingDetection)
    
    player.Functions.Notify('BUSTED: DEA seized ' .. Utils.formatMoney(seized) .. ' at ' .. business.name, 'error', 7000)
    
    -- Reset surveillance for this business
    if SurveillanceAlerts[playerID] then
        SurveillanceAlerts[playerID].businessIDs[businessID] = 0
        SurveillanceAlerts[playerID].level = math.max(0, SurveillanceAlerts[playerID].level - 1)
    end
end

-- Sell drugs to black market van
function SellToBlackMarket(source, vanID, drugType, amount)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then
        return { success = false, message = 'Player not found' }
    end
    
    if not Config.ProductionTypes[drugType] then
        return { success = false, message = 'Invalid drug type' }
    end
    
    -- Find van
    local van = nil
    for _, v in ipairs(Config.BlackMarketVans) do
        if v.id == vanID then
            van = v
            break
        end
    end
    
    if not van or not BlackMarketVans[vanID] or not BlackMarketVans[vanID].active then
        return { success = false, message = 'Van not available' }
    end
    
    -- Check player has drugs
    if not player.Functions.HasItem(drugType, amount) then
        return { success = false, message = 'You don\'t have ' .. amount .. 'g' }
    end
    
    -- Remove drugs
    player.Functions.RemoveItem(drugType, amount)
    
    -- Calculate payout (higher than street dealers, higher risk)
    local basePrice = Config.BlackMarketPrices[drugType] or 200
    local fluctuation = 0.85 + math.random() * 0.3  -- ±15% variation
    local pricePerGram = math.floor(basePrice * fluctuation)
    local totalPayout = pricePerGram * amount
    
    -- Give money (dirty cash)
    player.Functions.AddMoney('cash', totalPayout)
    
    -- High risk of detection
    local detectionRisk = Config.Surveillance.blackMarketMultiplier * Config.Surveillance.baseDetectionChance
    
    if math.random() < detectionRisk then
        TriggerSurveillanceAlert(source, 'black_market_' .. vanID)
        player.Functions.Notify('ALERT: Suspicious activity detected nearby!', 'error', 3000)
    end
    
    player.Functions.Notify('Sold ' .. amount .. 'g for ' .. Utils.formatMoney(totalPayout) .. ' (HIGH RISK)', 'success', 5000)
    
    return {
        success = true,
        amount = amount,
        pricePerGram = pricePerGram,
        totalPayout = totalPayout,
        riskLevel = detectionRisk
    }
end

-- Activate black market van (spawns it in world)
function ActivateBlackMarketVan(vanID)
    for _, van in ipairs(Config.BlackMarketVans) do
        if van.id == vanID then
            if BlackMarketVans[vanID] and BlackMarketVans[vanID].active then
                return  -- Already active
            end
            
            BlackMarketVans[vanID] = {
                id = vanID,
                active = true,
                startTime = os.time(),
                riskLevel = 0,
                currentWaypoint = 1
            }
            
            TriggerClientEvent('dea-cartel:client:spawnBlackMarketVan', -1, van)
            
            break
        end
    end
end

-- Deactivate black market van
function DeactivateBlackMarketVan(vanID)
    if BlackMarketVans[vanID] then
        BlackMarketVans[vanID].active = false
    end
    TriggerClientEvent('dea-cartel:client:despawnBlackMarketVan', -1, vanID)
end

-- Tick black market van system
CreateThread(function()
    while true do
        Wait(60000)  -- Check every minute
        
        for _, van in ipairs(Config.BlackMarketVans) do
            if BlackMarketVans[van.id] then
                local elapsed = (os.time() - BlackMarketVans[van.id].startTime) * 1000
                
                -- Deactivate after duration
                if elapsed > van.duration then
                    DeactivateBlackMarketVan(van.id)
                end
            else
                -- Chance to spawn new van
                if math.random() < van.spawnChance then
                    ActivateBlackMarketVan(van.id)
                end
            end
        end
        
        -- Clean up old surveillance data
        local now = os.time()
        for playerID, alert in pairs(SurveillanceAlerts) do
            if (now - alert.lastAlert) > 600 then  -- 10 minutes
                SurveillanceAlerts[playerID] = nil
            end
        end
    end
end)

-- Network events
RegisterNetEvent('dea-cartel:server:launderMoney', function(businessID, amount)
    local result = LaunderMoney(source, businessID, amount)
    TriggerClientEvent('dea-cartel:client:operationResult', source, result)
end)

RegisterNetEvent('dea-cartel:server:sellToBlackMarket', function(vanID, drugType, amount)
    local result = SellToBlackMarket(source, vanID, drugType, amount)
    TriggerClientEvent('dea-cartel:client:operationResult', source, result)
end)

RegisterNetEvent('dea-cartel:server:getLaunderingStatus', function(businessID)
    if not LaunderingOperations[businessID] then
        TriggerClientEvent('dea-cartel:client:operationResult', source, { success = false, message = 'Business not found' })
        return
    end
    
    local op = LaunderingOperations[businessID]
    local risk = 0
    for _, b in ipairs(Config.LaunderingBusinesses) do
        if b.id == businessID then
            risk = CalculateLaunderingRisk(op, b, source)
            break
        end
    end
    
    TriggerClientEvent('dea-cartel:client:launderingStatus', source, {
        success = true,
        operation = op,
        currentRisk = risk
    })
end)

print('^2[DEA-Cartel] ^7Sales & Laundering system initialized^0')
