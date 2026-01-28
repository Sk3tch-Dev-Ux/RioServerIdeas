local QBCore = exports['qb-core']:GetCoreObject()
local lib = exports.ox_lib

-- Track active bulk sale job
ActiveBulkSaleJob = nil
BulkSaleVehicle = nil

-- Handle bulk sale start
RegisterNetEvent('dea-cartel:client:startBulkSale', function(jobData)
    ActiveBulkSaleJob = jobData
    
    lib.notify({
        title = 'Bulk Sale Started',
        description = 'Deliver ' .. jobData.amount .. 'g to ' .. jobData.route.name,
        type = 'info',
        duration = 5000
    })
    
    -- Spawn delivery vehicle
    SpawnBulkSaleVehicle(jobData)
end)

RegisterNetEvent('dea-cartel:client:bulkSaleResult', function(result)
    if result.success then
        lib.notify({
            title = 'Bulk Sale Complete',
            description = 'Earned ' .. Utils.formatMoney(result.payout),
            type = 'success',
            duration = 5000
        })
        ActiveBulkSaleJob = nil
        if BulkSaleVehicle then
            DeleteEntity(BulkSaleVehicle)
            BulkSaleVehicle = nil
        end
    else
        lib.notify({
            title = 'Failed',
            description = result.message,
            type = 'error',
            duration = 3000
        })
    end
end)

-- Spawn delivery vehicle for bulk sale
function SpawnBulkSaleVehicle(jobData)
    local route = jobData.route
    local vehicleModel = Config.BulkVehicles[route.vehicleType]
    
    -- Load model
    RequestModel(GetHashKey(vehicleModel))
    local timeout = 0
    while not HasModelLoaded(GetHashKey(vehicleModel)) and timeout < 10000 do
        Wait(100)
        timeout = timeout + 100
    end
    
    if not HasModelLoaded(GetHashKey(vehicleModel)) then
        lib.notify({
            title = 'Error',
            description = 'Failed to load vehicle',
            type = 'error',
            duration = 3000
        })
        return
    end
    
    -- Spawn vehicle
    local vehicle = CreateVehicle(GetHashKey(vehicleModel), route.startCoords.x, route.startCoords.y, route.startCoords.z, route.heading or 0.0, true, false)
    SetVehicleOnGround(vehicle)
    BulkSaleVehicle = vehicle
    
    -- Add player to vehicle
    local player = PlayerPedId()
    SetPedIntoVehicle(player, vehicle, -1)
    
    -- Set GPS to destination
    SetNewWaypoint(route.endCoords.x, route.endCoords.y)
    
    lib.notify({
        title = 'Vehicle Spawned',
        description = 'Drive to the destination GPS marker',
        type = 'info',
        duration = 3000
    })
end

-- Monitor bulk sale delivery completion
CreateThread(function()
    while true do
        Wait(1000)
        
        if ActiveBulkSaleJob then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local destCoords = ActiveBulkSaleJob.route.endCoords
            local distance = #(playerCoords - destCoords)
            
             -- Check if at destination
             if distance < 50 then
                 lib.notify({
                     title = 'Delivery Zone Reached',
                     description = 'Park the vehicle and press [E] to complete',
                     type = 'info',
                     duration = 3000
                 })
                 
                 -- Once close enough, allow completion
                 if distance < 15 then
                     lib.progressBar({
                        duration = 5000,
                        label = 'Completing delivery...',
                        useWhileDead = false,
                        canCancel = false,
                        disable = {
                            car = true,
                            move = true,
                            combat = true
                        }
                    })
                    
                    TriggerServerEvent('dea-cartel:server:completeBulkSale', ActiveBulkSaleJob.jobID)
                    
                    lib.notify({
                        title = 'Delivery Complete',
                        description = 'Bulk sale completed successfully',
                        type = 'success',
                        duration = 3000
                    })
                    
                    ActiveBulkSaleJob = nil
                 end
             end
        end
    end
end)

-- Helper to get production type names
function Utils.getProductionTypeNames()
    local names = {}
    for name, _ in pairs(Config.ProductionTypes) do
        table.insert(names, name)
    end
    return names
end

function Utils.getOperationTypeNames()
    local names = {}
    for name, _ in pairs(Config.OperationTypes) do
        table.insert(names, name)
    end
    return names
end

-- Monitor active productions and show progress
CreateThread(function()
    while true do
        Wait(500)
        
        local playerCoords = GetEntityCoords(PlayerPedId())
        
        for opID, op in pairs(ClientOperations) do
            local distance = #(playerCoords - op.coords)
            
            -- Only process if nearby
            if distance < 200 then
                -- Show progress bar for active operations
                if op.status == 'growing' then
                    local coords = op.coords + vector3(0, 0, 1.5)
                    DrawText3D(coords, 'Growing: ' .. op.growPhase.progress .. '%', 1.0)
                    
                elseif op.status == 'producing' then
                    local coords = op.coords + vector3(0, 0, 1.5)
                    DrawText3D(coords, 'Producing: ' .. op.production.progress .. '%', 1.0)
                    
                elseif op.status == 'ready' then
                    local coords = op.coords + vector3(0, 0, 1.5)
                    DrawText3D(coords, 'Ready: ' .. op.production.currentYield .. 'g', 1.0)
                end
            end
        end
    end
end)

-- Utility function for drawing 3D text
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

-- Handled by interactions.lua - showNearbyOperations event



-- Show market prices
RegisterCommand('prices', function(source, args, rawCommand)
    local options = {
        {
            title = 'Market Prices',
            description = 'Current drug prices (fluctuate ±20%)',
            disabled = true
        }
    }
    
    for drugType, basePrice in pairs(Config.MarketPrices) do
        table.insert(options, {
            title = Config.ProductionTypes[drugType].label,
            description = Utils.formatMoney(basePrice) .. '/g',
            disabled = true
        })
    end
    
    lib.registerContext({
        id = 'market_prices_menu',
        title = 'Market Prices',
        options = options
    })
    
    lib.showContext('market_prices_menu')
end, false)

-- Show production info
RegisterCommand('prodinfo', function(source, args, rawCommand)
    if not args[1] then
        print('Usage: /prodinfo [productionType]')
        print('Types: ' .. table.concat(Utils.getProductionTypeNames(), ', '))
        return
    end
    
    local prodType = args[1]
    local config = Config.ProductionTypes[prodType]
    
    if not config then
        print('Invalid production type')
        return
    end
    
    local options = {
        {
            title = config.label,
            description = 'Production Information',
            disabled = true
        },
        {
            title = 'Setup Cost',
            description = Utils.formatMoney(config.setupCost),
            disabled = true
        },
        {
            title = 'Grow Time',
            description = (config.growTime / 60000) .. ' minutes',
            disabled = true
        },
        {
            title = 'Production Time',
            description = (config.productionTime / 60000) .. ' minutes',
            disabled = true
        },
        {
            title = 'Base Yield',
            description = config.baseYield .. 'g per cycle',
            disabled = true
        },
        {
            title = 'Market Price',
            description = Utils.formatMoney(Config.MarketPrices[prodType]) .. '/g',
            disabled = true
        }
    }
    
    lib.registerContext({
        id = 'prod_info_menu',
        title = 'Production Info',
        options = options
    })
    
    lib.showContext('prod_info_menu')
end, false)

print('^2[DEA-Cartel] ^7Production interactions loaded^0')
