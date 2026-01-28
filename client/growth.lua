local QBCore = exports['qb-core']:GetCoreObject()
local lib = exports.ox_lib

-- Client-side plant tracking
ClientPlants = {}
ClientProcessing = {}

-- Sync plants from server
RegisterNetEvent('dea-cartel:client:syncPlants', function(plants)
    ClientPlants = plants
end)

-- Sync processing batches from server
RegisterNetEvent('dea-cartel:client:syncProcessing', function(batches)
    ClientProcessing = batches
end)

-- Handle processing start
RegisterNetEvent('dea-cartel:client:startProcessing', function(batchData)
    lib.notify({
        title = 'Processing Started',
        description = 'Processing ' .. batchData.amount .. 'g for ' .. math.ceil(batchData.processTime / 60000) .. ' minutes',
        type = 'info',
        duration = 4000
    })
end)

-- Render plants in grow houses (3D visualization)
CreateThread(function()
    while true do
        Wait(Config.Performance.updateInterval)
        
        local playerCoords = GetEntityCoords(PlayerPedId())
        
        for opID, plants in pairs(ClientPlants) do
            local op = ClientOperations[opID]
            if op then
                local distance = #(playerCoords - op.coords)
                
                -- Only render if within render distance
                if distance < Config.Performance.plantRenderDistance then
                    for _, plant in ipairs(plants) do
                        RenderPlant(plant, op.coords)
                    end
                end
            end
        end
    end
end)

-- Render individual plant with growth stage visual
function RenderPlant(plant, baseCoords)
    local growConfig = Config.GrowSystem[plant.type]
    local stage = growConfig.stages[plant.stageIndex]
    
    -- Offset plants in a grid pattern around the base location
    local plantIndex = tonumber(plant.id:match('_(%d+)$')) or 1
    local gridSize = 4
    local spacing = 1.5
    
    local xOffset = ((plantIndex - 1) % gridSize) * spacing - (spacing * gridSize / 2)
    local yOffset = math.floor((plantIndex - 1) / gridSize) * spacing
    
    local plantCoords = baseCoords + vector3(xOffset, yOffset, 0.5)
    
    -- Draw 3D text with plant info
    DrawText3D(plantCoords, stage.name .. ' (' .. plant.health .. '%)', 0.5)
    
    if plant.harvestReady then
        DrawText3D(plantCoords + vector3(0, 0, 0.3), 'READY TO HARVEST', 0.6)
    end
end

-- Draw 3D text helper
function DrawText3D(coords, text, size)
    local onScreen, screenX, screenY = World3dToScreen2d(coords.x, coords.y, coords.z)
    if onScreen then
        SetTextScale(0.0, size)
        SetTextFont(4)
        SetTextProbes(true)
        SetColourOfNextTextComponent(255, 255, 255, 200)
        SetTextCentre(true)
        BeginTextCommandDisplayText('STRING')
        AddTextComponentString(text)
        EndTextCommandDisplayText(screenX, screenY)
    end
end

-- Plant seed at operation
function PlantSeedAtOp(opID)
    local op = ClientOperations[opID]
    if not op then return end
    
    local options = {
        {
            title = 'Cannabis Seeds',
            description = 'Plant a marijuana seed',
            icon = 'fas fa-leaf',
            onSelect = function()
                lib.progressBar({
                    duration = 5000,
                    label = 'Planting seed...',
                    useWhileDead = false,
                    canCancel = true,
                    disable = {
                        car = true,
                        move = true,
                        combat = true
                    }
                })
                
                TriggerServerEvent('dea-cartel:server:plantSeed', opID, 'marijuana')
                
                lib.notify({
                    title = 'Seed Planted',
                    description = 'Marijuana seed planted successfully',
                    type = 'success',
                    duration = 3000
                })
            end
        }
    }
    
    lib.registerContext({
        id = 'plant_seed_menu_' .. opID,
        title = 'Plant Seeds',
        options = options
    })
    
    lib.showContext('plant_seed_menu_' .. opID)
end

-- Harvest plants at operation
function HarvestPlantsAtOp(opID)
    if not ClientPlants[opID] then
        lib.notify({
            title = 'No Plants',
            description = 'No plants in this grow house',
            type = 'info',
            duration = 3000
        })
        return
    end
    
    local options = {}
    for i, plant in ipairs(ClientPlants[opID]) do
        if plant.harvestReady then
            local growConfig = Config.GrowSystem[plant.type]
            table.insert(options, {
                title = 'Plant #' .. i .. ' - ' .. growConfig.stages[plant.stageIndex].name,
                description = 'Quality: ' .. string.format('%.2f', plant.quality) .. ' | Health: ' .. plant.health .. '%',
                icon = 'fas fa-hand',
                args = plant.id,
                onSelect = function(data)
                    lib.progressBar({
                        duration = 8000,
                        label = 'Harvesting plant...',
                        useWhileDead = false,
                        canCancel = true,
                        disable = {
                            car = true,
                            move = true,
                            combat = true
                        }
                    })
                    
                    TriggerServerEvent('dea-cartel:server:harvestPlant', opID, data.args)
                    
                    lib.notify({
                        title = 'Plant Harvested',
                        description = 'Successfully harvested ' .. plant.type,
                        type = 'success',
                        duration = 3000
                    })
                end
            })
        end
    end
    
    if #options == 0 then
        lib.notify({
            title = 'No Ready Plants',
            description = 'No plants are ready to harvest yet',
            type = 'info',
            duration = 3000
        })
        return
    end
    
    lib.registerContext({
        id = 'harvest_menu_' .. opID,
        title = 'Harvest Plants',
        options = options
    })
    
    lib.showContext('harvest_menu_' .. opID)
end

-- Manage grow house upgrades
function ManageGrowUpgrades(opID)
    local op = ClientOperations[opID]
    if not op then return end
    
    if op.owner ~= GetPlayerServerId(PlayerId()) then
        lib.notify({
            title = 'Not Owner',
            description = 'You don\'t own this grow house',
            type = 'error',
            duration = 3000
        })
        return
    end
    
    if op.type ~= 'growhouse' then
        lib.notify({
            title = 'Wrong Type',
            description = 'Only grow houses can be upgraded',
            type = 'error',
            duration = 3000
        })
        return
    end
    
    local options = {
        {
            title = 'Current Upgrades',
            description = (op.upgrades and json.encode(op.upgrades) or 'None'),
            disabled = true
        }
    }
    
    local currentUpgrades = op.upgrades or {}
    
     for upgradeName, upgradeData in pairs(Config.Upgrades) do
         if not currentUpgrades[upgradeName] then
             table.insert(options, {
                 title = upgradeData.name,
                 description = upgradeData.description .. '\nCost: ' .. Utils.formatMoney(upgradeData.cost),
                 icon = upgradeData.icon,
                 args = upgradeName,
                 onSelect = function(data)
                     lib.progressBar({
                        duration = 10000,
                        label = 'Installing upgrade...',
                        useWhileDead = false,
                        canCancel = true,
                        disable = {
                            car = true,
                            move = true,
                            combat = true
                        }
                    })
                    
                    TriggerServerEvent('dea-cartel:server:buyUpgrade', opID, data.args)
                    
                    lib.notify({
                        title = 'Upgrade Installed',
                        description = upgradeData.name .. ' installed successfully',
                        type = 'success',
                        duration = 3000
                    })
                 end
             })
        else
            table.insert(options, {
                title = upgradeData.name .. ' (INSTALLED)',
                description = 'Already installed',
                icon = upgradeData.icon,
                disabled = true
            })
        end
    end
    
    lib.registerContext({
        id = 'grow_upgrades_menu_' .. opID,
        title = 'Grow House Upgrades',
        options = options
    })
    
    lib.showContext('grow_upgrades_menu_' .. opID)
end

-- View grow house details
function ViewGrowHouseDetails(opID)
    local op = ClientOperations[opID]
    if not op then return end
    
    local plantCount = (ClientPlants[opID] and #ClientPlants[opID]) or 0
    local growConfig = Config.GrowSystem[op.productionType]
    local upgrades = op.upgrades or {}
    
    local upgradeNames = {}
    for upgradeName, _ in pairs(upgrades) do
        if Config.Upgrades[upgradeName] then
            table.insert(upgradeNames, Config.Upgrades[upgradeName].name)
        end
    end
    
    local options = {
        {
            title = 'Grow House #' .. opID,
            description = 'Plants: ' .. plantCount .. '/' .. growConfig.maxPlants,
            disabled = true
        },
        {
            title = 'Plant Capacity',
            description = plantCount .. '/' .. growConfig.maxPlants .. ' plants',
            disabled = true
        },
        {
            title = 'Upgrades Installed',
            description = (#upgradeNames > 0 and table.concat(upgradeNames, ', ') or 'None'),
            disabled = true
        }
    }
    
    if op.owner == GetPlayerServerId(PlayerId()) then
        table.insert(options, {
            title = 'Plant Seeds',
            description = 'Add a new plant to grow',
            icon = 'fas fa-leaf',
            onSelect = function()
                PlantSeedAtOp(opID)
            end
        })
        
        table.insert(options, {
            title = 'Harvest Plants',
            description = 'Harvest ready plants',
            icon = 'fas fa-hand',
            onSelect = function()
                HarvestPlantsAtOp(opID)
            end
        })
        
        table.insert(options, {
            title = 'Manage Upgrades',
            description = 'Buy and upgrade grow house',
            icon = 'fas fa-hammer',
            onSelect = function()
                ManageGrowUpgrades(opID)
            end
        })
    end
    
    lib.registerContext({
        id = 'growhouse_details_' .. opID,
        title = 'Grow House Details',
        options = options
    })
    
    lib.showContext('growhouse_details_' .. opID)
end

-- View processing batch details
function ViewProcessingBatchDetails(batchID)
    if not ClientProcessing[batchID] then return end
    
    local batch = ClientProcessing[batchID]
    
    local options = {
        {
            title = 'Processing Batch',
            description = batch.drugType,
            disabled = true
        },
        {
            title = 'Progress',
            description = batch.progress .. '%',
            disabled = true
        },
        {
            title = 'Amount',
            description = batch.amount .. 'g (processing)',
            disabled = true
        },
        {
            title = 'Risk Level',
            description = string.format('%.0f%%', batch.risk * 100),
            disabled = true
        }
    }
    
    lib.registerContext({
        id = 'batch_details_' .. batchID,
        title = 'Processing Batch #' .. batchID,
        options = options
    })
    
    lib.showContext('batch_details_' .. batchID)
end



print('^2[DEA-Cartel] ^7Growth system client loaded^0')
