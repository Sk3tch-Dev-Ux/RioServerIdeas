local QBCore = exports['qb-core']:GetCoreObject()

-- Track plants in grow houses
GrowHousePlants = {}  -- { opID = { plant1, plant2, ... } }

-- Track processing batches
ProcessingBatches = {}  -- { batchID = { drugType, amount, progress, startTime } }

-- Spawn seeds at random locations
function SpawnSeeds(seedType)
    local amount = math.random(Config.SeedSpawns[seedType].amount.min, Config.SeedSpawns[seedType].amount.max)
    
    -- Seeds would spawn in world, for now just add to a random player's inventory
    -- In production, you'd use object spawning at specific coords
    for _, player in ipairs(GetPlayers()) do
        local qbPlayer = QBCore.Functions.GetPlayer(tonumber(player))
        if qbPlayer then
            qbPlayer.Functions.AddItem('marijuana_seed', amount)
            qbPlayer.Functions.Notify('Found ' .. amount .. ' cannabis seeds!', 'success', 3000)
            break
        end
    end
end

-- Plant a seed in grow house
function PlantSeed(source, opID, seedType)
    if not Operations[opID] then
        return { success = false, message = 'Operation not found' }
    end
    
    local op = Operations[opID]
    if op.owner ~= source then
        return { success = false, message = 'You don\'t own this operation' }
    end
    
    if op.type ~= 'growhouse' then
        return { success = false, message = 'Can only plant in grow houses' }
    end
    
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return { success = false, message = 'Player not found' } end
    
    -- Verify seed type matches operation
    if op.productionType ~= seedType then
        return { success = false, message = 'Wrong seed type for this grow house' }
    end
    
    -- Check player has seeds
    local seedItem = seedType .. '_seed'
    if not player.Functions.HasItem(seedItem, 1) then
        return { success = false, message = 'You don\'t have a ' .. seedItem }
    end
    
    -- Check plant capacity
    if not GrowHousePlants[opID] then
        GrowHousePlants[opID] = {}
    end
    
    local growConfig = Config.GrowSystem[seedType]
    if #GrowHousePlants[opID] >= growConfig.maxPlants then
        return { success = false, message = 'Grow house is full. Max: ' .. growConfig.maxPlants .. ' plants' }
    end
    
    -- Remove seed
    player.Functions.RemoveItem(seedItem, 1)
    
    -- Create plant
    local plant = {
        id = opID .. '_' .. #GrowHousePlants[opID] + 1,
        opID = opID,
        type = seedType,
        stageIndex = 1,
        startTime = os.time(),
        health = 100,
        quality = 0.8 + math.random() * 0.4,
        harvestReady = false
    }
    
    table.insert(GrowHousePlants[opID], plant)
    
    TriggerClientEvent('dea-cartel:client:syncPlants', -1, GrowHousePlants)
    
    return { success = true, message = 'Seed planted! Seedling stage started.' }
end

-- Harvest a plant
function HarvestPlant(source, opID, plantID)
    if not Operations[opID] then
        return { success = false, message = 'Operation not found' }
    end
    
    local op = Operations[opID]
    if op.owner ~= source then
        return { success = false, message = 'You don\'t own this operation' }
    end
    
    if not GrowHousePlants[opID] then
        return { success = false, message = 'No plants in this grow house' }
    end
    
    local plant = nil
    local plantIndex = nil
    for i, p in ipairs(GrowHousePlants[opID]) do
        if p.id == plantID then
            plant = p
            plantIndex = i
            break
        end
    end
    
    if not plant then
        return { success = false, message = 'Plant not found' }
    end
    
    if not plant.harvestReady then
        return { success = false, message = 'Plant not ready to harvest' }
    end
    
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return { success = false, message = 'Player not found' } end
    
    -- Calculate yield based on plant quality and upgrades
    local growConfig = Config.GrowSystem[plant.type]
    local baseYield = growConfig.baseYield
    local qualityMultiplier = plant.quality
    
    -- Apply upgrade bonuses
    local upgrades = op.upgrades or {}
    local yieldBonus = 1.0
    for upgradeName, _ in pairs(upgrades) do
        if Config.Upgrades[upgradeName] then
            yieldBonus = yieldBonus * Config.Upgrades[upgradeName].yieldBonus
        end
    end
    
    local finalYield = math.floor(baseYield * qualityMultiplier * yieldBonus)
    
    -- Give player the drug
    player.Functions.AddItem(plant.type, finalYield)
    
    -- Remove plant
    table.remove(GrowHousePlants[opID], plantIndex)
    
    TriggerClientEvent('dea-cartel:client:syncPlants', -1, GrowHousePlants)
    
    player.Functions.Notify('Harvested ' .. finalYield .. 'g of ' .. Config.ProductionTypes[plant.type].label, 'success', 5000)
    
    return {
        success = true,
        yield = finalYield,
        message = 'Plant harvested'
    }
end

-- Start drug processing batch (cocaine/meth)
function StartProcessingBatch(source, locationID, drugType, amount)
    if not Config.ProductionTypes[drugType] then
        return { success = false, message = 'Invalid drug type' }
    end
    
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return { success = false, message = 'Player not found' } end
    
    -- Find location
    local location = nil
    for _, loc in ipairs(Config.ProcessingLocations) do
        if loc.id == locationID then
            location = loc
            break
        end
    end
    
    if not location then
        return { success = false, message = 'Processing location not found' }
    end
    
    -- Check player has raw materials
    if not player.Functions.HasItem(drugType .. '_raw', amount) then
        return { success = false, message = 'You don\'t have ' .. amount .. 'g of raw material' }
    end
    
    -- Check location capacity
    if amount > location.capacity then
        return { success = false, message = 'Location capacity: ' .. location.capacity .. 'g' }
    end
    
    -- Remove raw materials
    player.Functions.RemoveItem(drugType .. '_raw', amount)
    
    -- Create batch
    local batchID = 'batch_' .. source .. '_' .. os.time()
    local processConfig = Config.GrowSystem[drugType]
    
    ProcessingBatches[batchID] = {
        id = batchID,
        player = source,
        playerName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
        locationID = locationID,
        drugType = drugType,
        amount = amount,
        startTime = os.time(),
        progress = 0,
        completed = false,
        risk = location.riskBase
    }
    
    TriggerClientEvent('dea-cartel:client:startProcessing', source, {
        batchID = batchID,
        drugType = drugType,
        amount = amount,
        processTime = processConfig.processTime,
        estimatedYield = math.floor(amount * 0.85)  -- 15% loss during processing
    })
    
    return {
        success = true,
        batchID = batchID,
        message = 'Processing batch started'
    }
end

-- Tick growth stages
function TickPlantGrowth()
    for opID, plants in pairs(GrowHousePlants) do
        if not Operations[opID] then
            GrowHousePlants[opID] = nil
        else
            local op = Operations[opID]
            local upgrades = op.upgrades or {}
            
            for i, plant in ipairs(plants) do
                if not plant.harvestReady then
                    local growConfig = Config.GrowSystem[plant.type]
                    local currentStage = growConfig.stages[plant.stageIndex]
                    
                    -- Apply growth speed bonus from upgrades
                    local speedBonus = 1.0
                    if upgrades.lighting then
                        speedBonus = speedBonus * Config.Upgrades.lighting.speedBonus
                    end
                    if upgrades.hydroponics then
                        speedBonus = speedBonus * Config.Upgrades.hydroponics.speedBonus
                    end
                    if upgrades.ventilation then
                        speedBonus = speedBonus * Config.Upgrades.ventilation.speedBonus
                    end
                    
                    local adjustedDuration = math.floor(currentStage.duration / speedBonus)
                    local elapsed = (os.time() - plant.startTime) * 1000
                    
                    -- Move to next stage
                    if elapsed >= adjustedDuration then
                        if plant.stageIndex < #growConfig.stages then
                            plant.stageIndex = plant.stageIndex + 1
                            plant.startTime = os.time()
                        else
                            -- Flowering complete, ready to harvest
                            plant.harvestReady = true
                        end
                    end
                end
            end
        end
    end
end

-- Tick processing batches
function TickProcessing()
    for batchID, batch in pairs(ProcessingBatches) do
        if batch.completed then
            ProcessingBatches[batchID] = nil
        else
            local processConfig = Config.GrowSystem[batch.drugType]
            local elapsed = (os.time() - batch.startTime) * 1000
            
            batch.progress = math.floor((elapsed / processConfig.processTime) * 100)
            
            if batch.progress >= 100 then
                batch.progress = 100
                batch.completed = true
                
                -- Calculate yield (15% loss during processing)
                local finalYield = math.floor(batch.amount * 0.85)
                
                local player = QBCore.Functions.GetPlayer(batch.player)
                if player then
                    player.Functions.AddItem(batch.drugType, finalYield)
                    player.Functions.Notify('Batch processed! Yield: ' .. finalYield .. 'g', 'success', 5000)
                end
            end
        end
    end
end

-- Tick loop
CreateThread(function()
    while true do
        Wait(Config.Performance.updateInterval)
        TickPlantGrowth()
        TickProcessing()
        TriggerClientEvent('dea-cartel:client:syncPlants', -1, GrowHousePlants)
        TriggerClientEvent('dea-cartel:client:syncProcessing', -1, ProcessingBatches)
    end
end)

-- Periodic seed spawning
CreateThread(function()
    while true do
        Wait(Config.Performance.seedSpawnCooldown)
        
        local spawnChances = {
            garbage = Config.SeedSpawns.garbage.chance,
            forest = Config.SeedSpawns.forest.chance,
            random = Config.SeedSpawns.random.chance
        }
        
        for spawnType, chance in pairs(spawnChances) do
            if math.random() < chance then
                SpawnSeeds(spawnType)
            end
        end
    end
end)

-- Network events
RegisterNetEvent('dea-cartel:server:plantSeed', function(opID, seedType)
    local result = PlantSeed(source, opID, seedType)
    TriggerClientEvent('dea-cartel:client:operationResult', source, result)
end)

RegisterNetEvent('dea-cartel:server:harvestPlant', function(opID, plantID)
    local result = HarvestPlant(source, opID, plantID)
    TriggerClientEvent('dea-cartel:client:operationResult', source, result)
end)

RegisterNetEvent('dea-cartel:server:startProcessing', function(locationID, drugType, amount)
    local result = StartProcessingBatch(source, locationID, drugType, amount)
    TriggerClientEvent('dea-cartel:client:operationResult', source, result)
end)

print('^2[DEA-Cartel] ^7Growth system initialized^0')
