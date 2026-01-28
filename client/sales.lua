local QBCore = exports['qb-core']:GetCoreObject()
local lib = exports.ox_lib

-- Client tracking
ClientBlackMarketVans = {}
ClientLaunderingStatus = {}
SurveillanceLevel = 0

-- Handle surveillance alerts
RegisterNetEvent('dea-cartel:client:surveilanceAlert', function(level)
    SurveillanceLevel = level
    
    local message = 'Light surveillance detected'
    local color = 'info'
    
    if level >= 2 then
        message = 'Heavy DEA surveillance!'
        color = 'warning'
    elseif level >= 4 then
        message = 'CRITICAL: Raid likely incoming!'
        color = 'error'
    end
    
    lib.notify({
        title = 'DEA Alert',
        description = message,
        type = color,
        duration = 4000
    })
end)

-- Handle wanted level
RegisterNetEvent('dea-cartel:client:setWanted', function(wantedLevel)
    SetPlayerWantedLevel(PlayerId(), wantedLevel)
    lib.notify({
        title = 'You are wanted!',
        description = 'Wanted level: ' .. wantedLevel,
        type = 'error',
        duration = 5000
    })
end)

-- Spawn black market van
RegisterNetEvent('dea-cartel:client:spawnBlackMarketVan', function(vanData)
    SpawnBlackMarketVan(vanData)
end)

-- Despawn black market van
RegisterNetEvent('dea-cartel:client:despawnBlackMarketVan', function(vanID)
    if ClientBlackMarketVans[vanID] and ClientBlackMarketVans[vanID].entity then
        DeleteEntity(ClientBlackMarketVans[vanID].entity)
    end
    ClientBlackMarketVans[vanID] = nil
end)

-- Spawn black market van in world
function SpawnBlackMarketVan(vanData)
    local model = GetHashKey(vanData.vehicleModel)
    
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 5000 do
        Wait(100)
        timeout = timeout + 100
    end
    
    if not HasModelLoaded(model) then
        lib.notify({
            title = 'Error',
            description = 'Failed to load van model',
            type = 'error',
            duration = 3000
        })
        return
    end
    
    -- Spawn vehicle
    local vehicle = CreateVehicle(model, vanData.spawn.x, vanData.spawn.y, vanData.spawn.z, 0.0, true, false)
    SetVehicleOnGround(vehicle)
    
    ClientBlackMarketVans[vanData.id] = {
        id = vanData.id,
        entity = vehicle,
        route = vanData.route,
        speed = vanData.speed,
        currentWaypoint = 1,
        active = true
    }
    
    -- Add target option
    exports.ox_target:addLocalEntity(vehicle, {
        {
            name = 'sell_black_market_' .. vanData.id,
            label = 'Sell to Van',
            icon = 'fas fa-handshake',
            distance = 3.0,
            onSelect = function()
                ShowBlackMarketMenu(vanData.id)
            end
        }
    })
    
    lib.notify({
        title = 'Black Market Van Spotted',
        description = vanData.name .. ' is now active!',
        type = 'warning',
        duration = 4000
    })
end

-- Show black market sales menu
function ShowBlackMarketMenu(vanID)
    local options = {
        {
            title = 'Black Market Van',
            description = 'High price, high risk',
            disabled = true
        }
    }
    
    for prodType, basePrice in pairs(Config.BlackMarketPrices) do
        table.insert(options, {
            title = 'Sell ' .. Config.ProductionTypes[prodType].label,
            description = Utils.formatMoney(basePrice) .. '/g ±15% | HIGH RISK',
            icon = Config.ProductionTypes[prodType].icon,
            args = prodType,
            onSelect = function(data)
                OpenBlackMarketSaleDialog(vanID, data.args)
            end
        })
    end
    
    lib.registerContext({
        id = 'black_market_menu_' .. vanID,
        title = 'Mobile Supply',
        options = options
    })
    
    lib.showContext('black_market_menu_' .. vanID)
end

-- Black market sale dialog
function OpenBlackMarketSaleDialog(vanID, drugType)
    local input = lib.inputDialog('Sell to Black Market Van', {
        { type = 'number', label = Config.ProductionTypes[drugType].label .. ' (grams)', description = 'WARNING: HIGH RISK!', required = true, min = 1 }
    })
    
    if input then
        local amount = input[1]
        
        lib.progressBar({
            duration = 6000,
            label = 'Completing transaction...',
            useWhileDead = false,
            canCancel = false,
            disable = {
                car = true,
                move = true,
                combat = true
            }
        })
        
        TriggerServerEvent('dea-cartel:server:sellToBlackMarket', vanID, drugType, amount)
        
        lib.notify({
            title = 'Transaction Complete',
            description = amount .. 'g sold to black market van',
            type = 'success',
            duration = 3000
        })
    end
end

-- Spawn laundering business NPCs and setup interactions
CreateThread(function()
    Wait(1000)
    
    for _, business in ipairs(Config.LaunderingBusinesses) do
        SpawnLaunderingBusiness(business)
    end
end)

-- Spawn laundering business
function SpawnLaunderingBusiness(businessData)
    -- Create target zone at business location
    local zoneID = exports.ox_target:addSphereZone({
        coords = businessData.coords,
        radius = 5.0,
        debug = false,
        options = {
            {
                name = 'launder_money_' .. businessData.id,
                label = 'Use ' .. businessData.name,
                icon = businessData.icon,
                distance = 5.0,
                onSelect = function()
                    ShowLaunderingMenu(businessData)
                end
            }
        }
    })
end

-- Show laundering business menu
function ShowLaunderingMenu(businessData)
    local options = {
        {
            title = businessData.name,
            description = businessData.type,
            disabled = true
        },
        {
            title = 'Conversion Rate',
            description = string.format('%.0f%%', businessData.conversionRate * 100),
            disabled = true
        },
        {
            title = 'Transaction Limit',
            description = Utils.formatMoney(businessData.maxTransaction),
            disabled = true
        },
        {
            title = 'Risk Level',
            description = string.format('%.0f%%', businessData.riskBase * 100),
            disabled = true
        },
        {
            title = 'Launder Money',
            description = 'Convert dirty cash to clean',
            icon = 'fas fa-money-bill',
            onSelect = function()
                OpenLaunderingDialog(businessData)
            end
        },
        {
            title = 'Check Status',
            description = 'View business details',
            icon = 'fas fa-info-circle',
            onSelect = function()
                TriggerServerEvent('dea-cartel:server:getLaunderingStatus', businessData.id)
            end
        }
    }
    
    lib.registerContext({
        id = 'launder_menu_' .. businessData.id,
        title = businessData.name,
        options = options
    })
    
    lib.showContext('launder_menu_' .. businessData.id)
end

-- Laundering dialog
function OpenLaunderingDialog(businessData)
    local input = lib.inputDialog('Launder Money at ' .. businessData.name, {
        { type = 'number', label = 'Amount ($)', description = 'Max: ' .. Utils.formatMoney(businessData.maxTransaction), required = true, min = 100, max = businessData.maxTransaction }
    })
    
     if input then
         local amount = input[1]
         
         -- Confirm with risk warning
         local confirmed = lib.alertDialog({
             header = 'Laundering Risk',
             content = 'Risk: ' .. string.format('%.0f%%', businessData.riskBase * 100) .. '% to be detected\nContinue?',
             centered = true,
             cancel = true,
             onConfirm = function()
                 lib.progressBar({
                    duration = 8000,
                    label = 'Laundering ' .. Utils.formatMoney(amount) .. '...',
                    useWhileDead = false,
                    canCancel = false,
                    disable = {
                        car = true,
                        move = true,
                        combat = true
                    }
                })
                
                TriggerServerEvent('dea-cartel:server:launderMoney', businessData.id, amount)
                
                lib.notify({
                    title = 'Money Laundered',
                    description = Utils.formatMoney(amount) .. ' converted to clean cash',
                    type = 'success',
                    duration = 4000
                })
             end
         })
        
        if confirmed then
            TriggerServerEvent('dea-cartel:server:launderMoney', businessData.id, amount)
        end
    end
end

-- Handle laundering status response
RegisterNetEvent('dea-cartel:client:launderingStatus', function(result)
    if not result.success then
        lib.notify({
            title = 'Error',
            description = result.message,
            type = 'error',
            duration = 3000
        })
        return
    end
    
    local op = result.operation
    local options = {
        {
            title = 'Business Status',
            description = 'Current capacity: ' .. math.floor(op.capacity.current / 1000) .. 'k / ' .. math.floor(op.capacity.max / 1000) .. 'k',
            disabled = true
        },
        {
            title = 'Total Laundered',
            description = Utils.formatMoney(op.totalLaundered),
            disabled = true
        },
        {
            title = 'Transactions',
            description = #op.transactions .. ' total',
            disabled = true
        },
        {
            title = 'Current Risk',
            description = string.format('%.0f%%', result.currentRisk * 100),
            disabled = true
        }
    }
    
    if #op.transactions > 0 then
        local lastTrans = op.transactions[#op.transactions]
        table.insert(options, {
            title = 'Last Transaction',
            description = 'Cleaned: ' .. Utils.formatMoney(lastTrans.cleaned) .. ' | ' .. os.date('%Y-%m-%d %H:%M:%S', lastTrans.timestamp),
            disabled = true
        })
    end
    
    lib.registerContext({
        id = 'launder_status',
        title = 'Business Status',
        options = options
    })
    
    lib.showContext('launder_status')
end)

-- Monitor and move black market vans along routes
CreateThread(function()
    while true do
        Wait(1000)
        
        for vanID, van in pairs(ClientBlackMarketVans) do
            if van.active and van.entity and DoesEntityExist(van.entity) then
                -- Get current waypoint
                local waypoint = van.route[van.currentWaypoint]
                if not waypoint then
                    van.currentWaypoint = 1
                    waypoint = van.route[1]
                end
                
                -- Move van towards waypoint
                local vanCoords = GetEntityCoords(van.entity)
                local distance = #(vanCoords - waypoint)
                
                if distance > 5.0 then
                    -- Calculate direction
                    local direction = (waypoint - vanCoords)
                    direction = direction / #direction
                    
                    -- Apply velocity (speed varies)
                    local velocity = direction * (van.speed / 10.0)
                    AddEntityVelocity(van.entity, velocity.x, velocity.y, velocity.z)
                else
                    -- Reached waypoint, move to next
                    van.currentWaypoint = van.currentWaypoint + 1
                    if van.currentWaypoint > #van.route then
                        van.currentWaypoint = 1
                    end
                end
            end
        end
    end
end)

-- Command to find black market vans nearby
RegisterCommand('findblackmarket', function(source, args, rawCommand)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local nearby = {}
    
    for vanID, van in pairs(ClientBlackMarketVans) do
        if van.active and van.entity and DoesEntityExist(van.entity) then
            local vanCoords = GetEntityCoords(van.entity)
            local distance = #(playerCoords - vanCoords)
            
            if distance < 500 then
                table.insert(nearby, {
                    id = vanID,
                    distance = math.floor(distance)
                })
            end
        end
    end
    
    if #nearby == 0 then
        lib.notify({
            title = 'No Vans Nearby',
            description = 'Check back later',
            type = 'info',
            duration = 3000
        })
        return
    end
    
    table.sort(nearby, function(a, b) return a.distance < b.distance end)
    
    local options = {}
    for _, item in ipairs(nearby) do
        table.insert(options, {
            title = 'Van #' .. item.id:sub(1, 15),
            description = item.distance .. 'm away',
            disabled = true
        })
    end
    
    lib.registerContext({
        id = 'blackmarket_nearby',
        title = 'Nearby Black Market Vans',
        options = options
    })
    
    lib.showContext('blackmarket_nearby')
end, false)

print('^2[DEA-Cartel] ^7Sales & Laundering client loaded^0')
