local QBCore = exports['qb-core']:GetCoreObject()

-- Active operations indexed by operation ID
Operations = {}
OperationID = 0

-- Get next operation ID
function GetNextOperationID()
    OperationID = OperationID + 1
    return OperationID
end

-- Create a new operation (grow house or lab)
function CreateOperation(operationType, productionType, coords, owner)
    local QBCore = exports['qb-core']:GetCoreObject()
    local player = QBCore.Functions.GetPlayer(owner)
    
    if not player then
        return { success = false, message = 'Player not found' }
    end
    
    if not Config.ProductionTypes[productionType] then
        return { success = false, message = 'Invalid production type' }
    end
    
    -- Check money
    local setupCost = Utils.getSetupCost(productionType)
    if player.PlayerData.money.cash < setupCost then
        return { success = false, message = 'Not enough cash. Need: ' .. Utils.formatMoney(setupCost) }
    end
    
    -- Deduct setup cost
    player.Functions.RemoveMoney('cash', setupCost)
    
    -- Create operation
    local opID = GetNextOperationID()
    Operations[opID] = {
        id = opID,
        owner = owner,
        ownerName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
        type = operationType,
        productionType = productionType,
        coords = coords,
        createdAt = os.time(),
        status = 'idle', -- idle, growing, producing, ready
        supplies = {},
        production = {
            currentYield = 0,
            quality = 1.0,
            progress = 0, -- 0-100
            startTime = nil
        },
        growPhase = {
            progress = 0, -- 0-100
            startTime = nil,
            complete = false
        }
    }
    
    player.Functions.Notify('Operation ' .. opID .. ' created at ' .. coords, 'success', 5000)
    TriggerClientEvent('dea-cartel:client:syncOperations', -1, Operations)
    
    -- Add heat for suspicious activity
    AddPlayerHeat(owner, Config.HeatSystem.playerHeat.events.operationDestroyed, 'Created grow operation')
    
    return { success = true, opID = opID, message = 'Operation created' }
end

-- Resupply an operation
function ResupplyOperation(opID, owner)
    if not Operations[opID] then
        return { success = false, message = 'Operation not found' }
    end
    
    local op = Operations[opID]
    if op.owner ~= owner then
        return { success = false, message = 'You do not own this operation' }
    end
    
    local QBCore = exports['qb-core']:GetCoreObject()
    local player = QBCore.Functions.GetPlayer(owner)
    if not player then return { success = false, message = 'Player not found' } end
    
    local supplyCost = Utils.getSupplyCost(op.productionType)
    if player.PlayerData.money.cash < supplyCost then
        return { success = false, message = 'Not enough cash. Need: ' .. Utils.formatMoney(supplyCost) }
    end
    
    player.Functions.RemoveMoney('cash', supplyCost)
    op.supplies.level = (op.supplies.level or 0) + 1
    op.status = 'ready'
    
    player.Functions.Notify('Operation resupplied!', 'success', 3000)
    TriggerClientEvent('dea-cartel:client:syncOperations', -1, Operations)
    
    return { success = true, message = 'Resupplied' }
end

-- Start production cycle
function StartProduction(opID, owner)
    if not Operations[opID] then
        return { success = false, message = 'Operation not found' }
    end
    
    local op = Operations[opID]
    if op.owner ~= owner then
        return { success = false, message = 'You do not own this operation' }
    end
    
    if op.status == 'producing' or op.status == 'growing' then
        return { success = false, message = 'Already in progress' }
    end
    
    if op.supplies.level == nil or op.supplies.level < 1 then
        return { success = false, message = 'Need to resupply first' }
    end
    
    local prodConfig = Config.ProductionTypes[op.productionType]
    
    -- Check if grow phase needed
    if prodConfig.growTime > 0 and not op.growPhase.complete then
        op.status = 'growing'
        op.growPhase.startTime = os.time()
        op.growPhase.progress = 0
    else
        op.status = 'producing'
        op.production.startTime = os.time()
        op.production.progress = 0
    end
    
    TriggerClientEvent('dea-cartel:client:syncOperations', -1, Operations)
    return { success = true, message = 'Production started' }
end

-- Collect finished product
function CollectProduction(opID, owner)
    if not Operations[opID] then
        return { success = false, message = 'Operation not found' }
    end
    
    local op = Operations[opID]
    if op.owner ~= owner then
        return { success = false, message = 'You do not own this operation' }
    end
    
    if op.status ~= 'ready' then
        return { success = false, message = 'Production not ready' }
    end
    
    local QBCore = exports['qb-core']:GetCoreObject()
    local player = QBCore.Functions.GetPlayer(owner)
    if not player then return { success = false, message = 'Player not found' } end
    
    -- Give player the drugs
    local yield = op.production.currentYield
    player.Functions.AddItem(op.productionType, yield)
    
    player.Functions.Notify('Collected ' .. yield .. 'g of ' .. Config.ProductionTypes[op.productionType].label, 'success', 5000)
    
    -- Reset production
    op.status = 'idle'
    op.supplies.level = (op.supplies.level or 1) - 1
    op.production = { currentYield = 0, quality = 1.0, progress = 0, startTime = nil }
    op.growPhase = { progress = 0, startTime = nil, complete = false }
    
    TriggerClientEvent('dea-cartel:client:syncOperations', -1, Operations)
    
    return { success = true, yield = yield, message = 'Collected production' }
end

-- Tick production timers (called periodically)
function TickProductions()
    for opID, op in pairs(Operations) do
        local prodConfig = Config.ProductionTypes[op.productionType]
        
        -- Grow phase
        if op.status == 'growing' and op.growPhase.startTime then
            local elapsed = (os.time() - op.growPhase.startTime) * 1000
            op.growPhase.progress = math.floor((elapsed / prodConfig.growTime) * 100)
            
            if op.growPhase.progress >= 100 then
                op.growPhase.progress = 100
                op.growPhase.complete = true
                op.status = 'producing'
                op.production.startTime = os.time()
            end
        end
        
        -- Production phase
        if op.status == 'producing' and op.production.startTime then
            local elapsed = (os.time() - op.production.startTime) * 1000
            op.production.progress = math.floor((elapsed / prodConfig.productionTime) * 100)
            
            if op.production.progress >= 100 then
                -- Calculate final yield and quality
                local qualityFactor = Utils.calculateQuality(op.supplies.level or 1, math.random())
                local supplyBonus = (op.supplies.level or 1) * 0.5
                local yield = Utils.calculateYield(op.productionType, qualityFactor, supplyBonus)
                
                op.production.progress = 100
                op.production.currentYield = yield
                op.production.quality = qualityFactor
                op.status = 'ready'
            end
        end
    end
end

-- Tick loop
CreateThread(function()
    while true do
        Wait(1000)
        TickProductions()
        TriggerClientEvent('dea-cartel:client:syncOperations', -1, Operations)
    end
end)

-- Network events
RegisterNetEvent('dea-cartel:server:createOperation', function(operationType, productionType, coords)
    local result = CreateOperation(operationType, productionType, coords, source)
    TriggerClientEvent('dea-cartel:client:operationResult', source, result)
end)

RegisterNetEvent('dea-cartel:server:resupply', function(opID)
    local result = ResupplyOperation(opID, source)
    TriggerClientEvent('dea-cartel:client:operationResult', source, result)
end)

RegisterNetEvent('dea-cartel:server:startProduction', function(opID)
    local result = StartProduction(opID, source)
    TriggerClientEvent('dea-cartel:client:operationResult', source, result)
end)

RegisterNetEvent('dea-cartel:server:collectProduction', function(opID)
    local result = CollectProduction(opID, source)
    TriggerClientEvent('dea-cartel:client:operationResult', source, result)
end)

print('^2[DEA-Cartel] ^7Server initialized^0')
