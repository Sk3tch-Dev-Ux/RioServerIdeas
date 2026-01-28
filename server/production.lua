local QBCore = exports['qb-core']:GetCoreObject()

-- Track active bulk sale jobs
BulkSaleJobs = {}

-- Sell drugs to street dealer (NPC)
function SellToDealer(source, dealerID, drugType, amount)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then
        return { success = false, message = 'Player not found' }
    end
    
    if not Config.ProductionTypes[drugType] then
        return { success = false, message = 'Invalid drug type' }
    end
    
    if not Config.Dealers[dealerID] then
        return { success = false, message = 'Dealer not found' }
    end
    
    -- Validate player has drugs
    if not player.Functions.HasItem(drugType, amount) then
        return { success = false, message = 'You don\'t have ' .. amount .. 'g' }
    end
    
    -- Find the tier for this dealer and drug type
    local dealer = Config.Dealers[dealerID]
    local dealerTier = nil
    
    for _, tier in ipairs(dealer.tiers) do
        if tier.drugType == drugType then
            dealerTier = tier
            break
        end
    end
    
    if not dealerTier then
        return { success = false, message = dealer.name .. ' doesn\'t buy ' .. Config.ProductionTypes[drugType].label }
    end
    
    -- Check quantity limit
    if amount > dealerTier.maxQuantity then
        return { success = false, message = 'Too much! Max: ' .. dealerTier.maxQuantity .. 'g' }
    end
    
    -- Calculate payout (base price with dealer markup/discount)
    local basePrice = Config.MarketPrices[drugType] or 100
    local paymentMultiplier = dealerTier.minPayment + math.random() * (dealerTier.maxPayment - dealerTier.minPayment)
    local pricePerGram = math.floor(basePrice * paymentMultiplier)
    local totalPayout = pricePerGram * amount
    
    -- Remove drugs
    player.Functions.RemoveItem(drugType, amount)
    
    -- Give money (dirty cash)
    player.Functions.AddMoney('cash', totalPayout)
    
    player.Functions.Notify('Sold ' .. amount .. 'g to ' .. dealer.name .. ' for ' .. Utils.formatMoney(totalPayout), 'success', 5000)
    
    -- Add heat for drug dealing
    AddPlayerHeat(source, Config.HeatSystem.playerHeat.events.suspiciousActivity, 'Drug sale to dealer')
    
    return {
        success = true,
        amount = amount,
        pricePerGram = pricePerGram,
        totalPayout = totalPayout,
        dealerName = dealer.name
    }
end

-- Sell drugs to dealer (generic, replaced by SellToDealer)
function SellDrugs(source, drugType, amount)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then
        return { success = false, message = 'Player not found' }
    end
    
    if not Config.ProductionTypes[drugType] then
        return { success = false, message = 'Invalid drug type' }
    end
    
    if not player.Functions.HasItem(drugType, amount) then
        return { success = false, message = 'You don\'t have ' .. amount .. 'g' }
    end
    
    -- Calculate payout (base price with market fluctuation ±20%)
    local basePrice = Config.MarketPrices[drugType] or 100
    local fluctuation = 0.8 + math.random() * 0.4
    local pricePerGram = math.floor(basePrice * fluctuation)
    local totalPayout = pricePerGram * amount
    
    -- Remove drugs
    player.Functions.RemoveItem(drugType, amount)
    
    -- Give money (dirty cash)
    player.Functions.AddMoney('cash', totalPayout)
    
    player.Functions.Notify('Sold ' .. amount .. 'g for ' .. Utils.formatMoney(totalPayout), 'success', 5000)
    
    return {
        success = true,
        amount = amount,
        pricePerGram = pricePerGram,
        totalPayout = totalPayout
    }
end

-- Get operation status (detailed info)
function GetOperationStatus(opID, source)
    if not Operations[opID] then
        return { success = false, message = 'Operation not found' }
    end
    
    local op = Operations[opID]
    local player = QBCore.Functions.GetPlayer(source)
    
    -- Only owner can view detailed status
    if op.owner ~= source and (not player or not player.PlayerData.job.name == 'police') then
        return { success = false, message = 'Access denied' }
    end
    
    return {
        success = true,
        operation = op
    }
end

-- Destroy an operation (for owner or after seizure)
function DestroyOperation(opID, source)
    if not Operations[opID] then
        return { success = false, message = 'Operation not found' }
    end
    
    local op = Operations[opID]
    local player = QBCore.Functions.GetPlayer(source)
    
    if op.owner ~= source and (not player or player.PlayerData.job.name ~= 'police') then
        return { success = false, message = 'Access denied' }
    end
    
    Operations[opID] = nil
    TriggerClientEvent('dea-cartel:client:syncOperations', -1, Operations)
    
    return { success = true, message = 'Operation destroyed' }
end

-- List all operations (for debugging/admin)
function ListOperations(source)
    local player = QBCore.Functions.GetPlayer(source)
    
    -- Only admins or police can list all
    if player.PlayerData.job.name ~= 'police' and player.PlayerData.job.isboss == false then
        return { success = false, message = 'Access denied' }
    end
    
    local opList = {}
    for opID, op in pairs(Operations) do
        table.insert(opList, {
            id = op.id,
            owner = op.ownerName,
            type = op.type,
            productionType = op.productionType,
            status = op.status,
            coords = op.coords
        })
    end
    
    return { success = true, operations = opList }
end

-- Start a bulk sale delivery job
function StartBulkSaleJob(source, routeID, drugType, amount)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then
        return { success = false, message = 'Player not found' }
    end
    
    if not Config.ProductionTypes[drugType] then
        return { success = false, message = 'Invalid drug type' }
    end
    
    -- Find route
    local route = nil
    for _, r in ipairs(Config.BulkSaleRoutes) do
        if r.id == routeID then
            route = r
            break
        end
    end
    
    if not route then
        return { success = false, message = 'Route not found' }
    end
    
    -- Check minimum quantity
    if amount < route.minQuantity then
        return { success = false, message = 'Need at least ' .. route.minQuantity .. 'g. Have: ' .. amount .. 'g' }
    end
    
    -- Check player has drugs
    if not player.Functions.HasItem(drugType, amount) then
        return { success = false, message = 'You don\'t have ' .. amount .. 'g' }
    end
    
    -- Remove drugs (will be returned if job fails)
    player.Functions.RemoveItem(drugType, amount)
    
    -- Create bulk sale job
    local jobID = 'bulk_' .. source .. '_' .. os.time()
    BulkSaleJobs[jobID] = {
        id = jobID,
        player = source,
        playerName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
        routeID = routeID,
        route = route,
        drugType = drugType,
        amount = amount,
        startTime = os.time(),
        completed = false,
        status = 'in_progress'
    }
    
    -- Calculate payout
    local basePrice = Config.MarketPrices[drugType]
    local multiplier = Config.BulkPaymentMultipliers[drugType] or 1.0
    local bulkBonus = 1.0 + (amount / 1000) * 0.1  -- 10% bonus per 1000g
    local totalPayout = math.floor(route.reward * multiplier * bulkBonus)
    
    TriggerClientEvent('dea-cartel:client:startBulkSale', source, {
        jobID = jobID,
        route = route,
        amount = amount,
        estimatedPayout = totalPayout,
        drugType = Config.ProductionTypes[drugType].label
    })
    
    return {
        success = true,
        jobID = jobID,
        estimatedPayout = totalPayout,
        message = 'Bulk sale job started. Deliver to ' .. route.name
    }
end

-- Complete a bulk sale delivery
function CompleteBulkSale(source, jobID)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then
        return { success = false, message = 'Player not found' }
    end
    
    if not BulkSaleJobs[jobID] then
        return { success = false, message = 'Job not found' }
    end
    
    local job = BulkSaleJobs[jobID]
    
    if job.player ~= source then
        return { success = false, message = 'This is not your job' }
    end
    
    if job.completed then
        return { success = false, message = 'Job already completed' }
    end
    
    -- Check if job timed out
    local elapsed = (os.time() - job.startTime) * 1000
    if elapsed > job.route.timeout then
        -- Return drugs on failure
        player.Functions.AddItem(job.drugType, job.amount)
        job.completed = true
        return { success = false, message = 'Delivery timed out. Drugs returned.' }
    end
    
    -- Calculate final payout
    local basePrice = Config.MarketPrices[job.drugType]
    local multiplier = Config.BulkPaymentMultipliers[job.drugType] or 1.0
    local bulkBonus = 1.0 + (job.amount / 1000) * 0.1
    local totalPayout = math.floor(job.route.reward * multiplier * bulkBonus)
    
    -- Give payout
    player.Functions.AddMoney('cash', totalPayout)
    
    job.completed = true
    job.status = 'completed'
    
    player.Functions.Notify('Delivery complete! Earned ' .. Utils.formatMoney(totalPayout), 'success', 5000)
    
    return {
        success = true,
        payout = totalPayout,
        message = 'Delivery successful'
    }
end

-- Cancel bulk sale (returns drugs)
function CancelBulkSale(source, jobID)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then
        return { success = false, message = 'Player not found' }
    end
    
    if not BulkSaleJobs[jobID] then
        return { success = false, message = 'Job not found' }
    end
    
    local job = BulkSaleJobs[jobID]
    
    if job.player ~= source then
        return { success = false, message = 'This is not your job' }
    end
    
    if job.completed then
        return { success = false, message = 'Job already completed' }
    end
    
    -- Return drugs
    player.Functions.AddItem(job.drugType, job.amount)
    job.completed = true
    job.status = 'cancelled'
    
    player.Functions.Notify('Bulk sale cancelled. Drugs returned.', 'warning', 3000)
    
    return { success = true, message = 'Job cancelled' }
end

-- Network events for production
RegisterNetEvent('dea-cartel:server:sellToDealer', function(dealerID, drugType, amount)
    local result = SellToDealer(source, dealerID, drugType, amount)
    TriggerClientEvent('dea-cartel:client:operationResult', source, result)
end)

RegisterNetEvent('dea-cartel:server:startBulkSale', function(routeID, drugType, amount)
    local result = StartBulkSaleJob(source, routeID, drugType, amount)
    TriggerClientEvent('dea-cartel:client:operationResult', source, result)
end)

RegisterNetEvent('dea-cartel:server:completeBulkSale', function(jobID)
    local result = CompleteBulkSale(source, jobID)
    TriggerClientEvent('dea-cartel:client:bulkSaleResult', source, result)
end)

RegisterNetEvent('dea-cartel:server:cancelBulkSale', function(jobID)
    local result = CancelBulkSale(source, jobID)
    TriggerClientEvent('dea-cartel:client:operationResult', source, result)
end)

-- Buy grow house upgrade
function BuyUpgrade(source, opID, upgradeName)
    if not Operations[opID] then
        return { success = false, message = 'Operation not found' }
    end
    
    local op = Operations[opID]
    if op.owner ~= source then
        return { success = false, message = 'You don\'t own this operation' }
    end
    
    if op.type ~= 'growhouse' then
        return { success = false, message = 'Only grow houses can have upgrades' }
    end
    
    if not Config.Upgrades[upgradeName] then
        return { success = false, message = 'Invalid upgrade' }
    end
    
    local upgradeData = Config.Upgrades[upgradeName]
    
    -- Check if already has upgrade
    if op.upgrades and op.upgrades[upgradeName] then
        return { success = false, message = 'Already installed' }
    end
    
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return { success = false, message = 'Player not found' } end
    
    -- Check money
    if player.PlayerData.money.cash < upgradeData.cost then
        return { success = false, message = 'Not enough cash. Need: ' .. Utils.formatMoney(upgradeData.cost) }
    end
    
    -- Deduct money
    player.Functions.RemoveMoney('cash', upgradeData.cost)
    
    -- Add upgrade
    if not op.upgrades then
        op.upgrades = {}
    end
    op.upgrades[upgradeName] = true
    
    player.Functions.Notify('Upgrade installed: ' .. upgradeData.name, 'success', 5000)
    TriggerClientEvent('dea-cartel:client:syncOperations', -1, Operations)
    
    return { success = true, message = 'Upgrade installed' }
end

RegisterNetEvent('dea-cartel:server:buyUpgrade', function(opID, upgradeName)
    local result = BuyUpgrade(source, opID, upgradeName)
    TriggerClientEvent('dea-cartel:client:operationResult', source, result)
end)

RegisterNetEvent('dea-cartel:server:sellDrugs', function(drugType, amount)
    local result = SellDrugs(source, drugType, amount)
    TriggerClientEvent('dea-cartel:client:operationResult', source, result)
end)

RegisterNetEvent('dea-cartel:server:getOperationStatus', function(opID)
    local result = GetOperationStatus(opID, source)
    TriggerClientEvent('dea-cartel:client:operationStatus', source, result)
end)

RegisterNetEvent('dea-cartel:server:destroyOperation', function(opID)
    local result = DestroyOperation(opID, source)
    TriggerClientEvent('dea-cartel:client:operationResult', source, result)
end)

print('^2[DEA-Cartel] ^7Production system initialized^0')
