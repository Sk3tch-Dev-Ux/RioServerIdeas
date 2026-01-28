local QBCore = exports['qb-core']:GetCoreObject()
local lib = exports.ox_lib

-- Consolidated interaction system using ox_lib and ox_target

-- ========== OPERATION MANAGEMENT INTERACTIONS ==========

-- Add target zone for every operation (synced from server)
CreateThread(function()
    while true do
        Wait(5000)
        
        -- Update operation zones when operations change
        for opID, op in pairs(ClientOperations or {}) do
            if op and op.coords then
                -- Check if zone already exists (simplified - would need zone tracking)
                -- For now, operations are handled in main.lua with ShowOperationMenu
            end
        end
    end
end)

-- ========== DEA COMMAND CENTER INTERACTIONS ==========

-- Spawn DEA command center targets
CreateThread(function()
    Wait(2000)
    
    for _, center in ipairs(Config.DEACommandCenters) do
        -- Main interaction zone
        exports.ox_target:addSphereZone({
            coords = center.coords,
            radius = 10.0,
            debug = false,
            options = {
                {
                    name = 'dea_briefing_' .. center.id,
                    label = 'DEA Operations',
                    icon = 'fas fa-shield',
                    distance = 10.0,
                    groups = 'police',
                    onSelect = function()
                        TriggerEvent('dea-cartel:client:openDEAMenu')
                    end
                }
            }
        })
    end
end)

-- ========== DEALER STASH HOUSE INTERACTIONS ==========

-- Stash house for storing items
function SetupStashHouseZones()
    for _, zone in ipairs(Config.AvailableZones or {}) do
        exports.ox_target:addSphereZone({
            coords = zone.coords,
            radius = 5.0,
            debug = false,
            options = {
                {
                    name = 'stash_zone_' .. zone.name:gsub(' ', '_'),
                    label = 'Stash: ' .. zone.name,
                    icon = 'fas fa-box',
                    distance = 5.0,
                    onSelect = function()
                        lib.notify({
                            title = zone.name,
                            description = 'Stash house interaction',
                            type = 'info',
                            duration = 3000
                        })
                    end
                }
            }
        })
    end
end

-- Initialize stash zones when ready
SetTimeout(3000, SetupStashHouseZones)

-- ========== QUICK ACCESS MENUS ==========

-- Global hotkey to open criminal menu
RegisterKeyMapping('openmenu', 'Open Criminal Menu', 'keyboard', 'F6')
RegisterCommand('openmenu', function(source, args, rawCommand)
    TriggerEvent('dea-cartel:client:openMainMenu')
end, false)

-- Main menu dispatcher
RegisterNetEvent('dea-cartel:client:openMainMenu', function()
    local player = QBCore.GetPlayerData()
    
    if player.job.name == 'police' then
        TriggerEvent('dea-cartel:client:openDEAMenu')
    else
        TriggerEvent('dea-cartel:client:openCriminalMenu')
    end
end)

-- Criminal main menu
RegisterNetEvent('dea-cartel:client:openCriminalMenu', function()
    local options = {
        {
            title = 'Criminal Operations',
            description = 'Manage your illegal activities',
            disabled = true
        },
        {
            title = 'My Operations',
            description = 'Grow houses and labs',
            icon = 'fas fa-flask',
            arrow = true,
            onSelect = function()
                TriggerEvent('dea-cartel:client:showMyOperations')
            end
        },
        {
            title = 'Nearby Operations',
            description = 'Find grow houses and labs',
            icon = 'fas fa-map',
            arrow = true,
            onSelect = function()
                TriggerEvent('dea-cartel:client:showNearbyOperations')
            end
        },
        {
            title = 'Market',
            description = 'Sell drugs and manage sales',
            icon = 'fas fa-money-bill-wave',
            arrow = true,
            onSelect = function()
                TriggerEvent('dea-cartel:client:openMarketMenu')
            end
        },
        {
            title = 'Safe Houses',
            description = 'Find hideouts and defenses',
            icon = 'fas fa-shield-halved',
            arrow = true,
            onSelect = function()
                TriggerEvent('dea-cartel:client:openHideoutMenu')
            end
        },
        {
            title = 'Survive & Thrive',
            description = 'Bribe, recruit, evade',
            icon = 'fas fa-person-hiking',
            arrow = true,
            onSelect = function()
                TriggerEvent('dea-cartel:client:openSurvivalMenu')
            end
        }
    }
    
    lib.registerContext({
        id = 'criminal_main_menu',
        title = 'Criminal Operations',
        options = options
    })
    
    lib.showContext('criminal_main_menu')
end)

-- Market menu
RegisterNetEvent('dea-cartel:client:openMarketMenu', function()
    local options = {
        {
            title = 'Drug Market',
            description = 'Sell to dealers or black market',
            disabled = true
        },
        {
            title = 'Street Dealers',
            description = 'Safe sales, lower price',
            icon = 'fas fa-handshake',
            onSelect = function()
                TriggerEvent('dea-cartel:client:showNearbyDealers')
            end
        },
        {
            title = 'Black Market Van',
            description = 'High price, high risk',
            icon = 'fas fa-truck',
            onSelect = function()
                TriggerEvent('dea-cartel:client:findBlackMarketVan')
            end
        },
        {
            title = 'Bulk Delivery',
            description = 'Large quantities via vehicle',
            icon = 'fas fa-boxes-stacked',
            onSelect = function()
                OpenBulkSaleMenu()
            end
        },
        {
            title = 'Launder Money',
            description = 'Convert dirty to clean cash',
            icon = 'fas fa-coins',
            onSelect = function()
                TriggerEvent('dea-cartel:client:findLaunderingBusiness')
            end
        },
        {
            title = 'Market Prices',
            description = 'Check current drug prices',
            icon = 'fas fa-chart-line',
            onSelect = function()
                TriggerEvent('dea-cartel:client:showMarketPrices')
            end
        }
    }
    
    lib.registerContext({
        id = 'market_menu',
        title = 'Drug Market',
        menu = 'criminal_main_menu',
        options = options
    })
    
    lib.showContext('market_menu')
end)

-- Nearby dealers
RegisterNetEvent('dea-cartel:client:showNearbyDealers', function()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local options = {}
    
    for dealerID, dealer in ipairs(Config.Dealers) do
        local distance = #(playerCoords - dealer.coords)
        if distance < 200 then
            table.insert(options, {
                title = dealer.name,
                description = distance .. 'm away',
                icon = 'fas fa-user',
                onSelect = function()
                    SetNewWaypoint(dealer.coords.x, dealer.coords.y)
                    lib.notify({
                        title = 'GPS Set',
                        description = 'Heading to ' .. dealer.name,
                        type = 'success',
                        duration = 3000
                    })
                end
            })
        end
    end
    
    if #options == 0 then
        lib.notify({
            title = 'No Dealers',
            description = 'No dealers found nearby',
            type = 'info',
            duration = 3000
        })
        return
    end
    
    lib.registerContext({
        id = 'nearby_dealers_menu',
        title = 'Nearby Dealers',
        menu = 'market_menu',
        options = options
    })
    
    lib.showContext('nearby_dealers_menu')
end)

-- Find black market van
RegisterNetEvent('dea-cartel:client:findBlackMarketVan', function()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local nearby = {}
    
    for vanID, van in pairs(ClientBlackMarketVans or {}) do
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
            title = 'No Vans',
            description = 'Black market vans not in area',
            type = 'warning',
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
            onSelect = function()
                SetNewWaypoint(GetEntityCoords(ClientBlackMarketVans[item.id].entity).x, GetEntityCoords(ClientBlackMarketVans[item.id].entity).y)
            end
        })
    end
    
    lib.registerContext({
        id = 'blackmarket_vans_menu',
        title = 'Black Market Vans',
        menu = 'market_menu',
        options = options
    })
    
    lib.showContext('blackmarket_vans_menu')
end)

-- Find laundering business
RegisterNetEvent('dea-cartel:client:findLaunderingBusiness', function()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local options = {}
    
    for _, business in ipairs(Config.LaunderingBusinesses) do
        local distance = #(playerCoords - business.coords)
        table.insert(options, {
            title = business.name,
            description = distance .. 'm | Rate: ' .. string.format('%.0f%%', business.conversionRate * 100),
            icon = business.icon,
            onSelect = function()
                SetNewWaypoint(business.coords.x, business.coords.y)
            end
        })
    end
    
    lib.registerContext({
        id = 'laundering_menu',
        title = 'Money Laundering',
        menu = 'market_menu',
        options = options
    })
    
    lib.showContext('laundering_menu')
end)

-- Market prices
RegisterNetEvent('dea-cartel:client:showMarketPrices', function()
    local options = {
        {
            title = 'Current Market Prices',
            description = 'Prices fluctuate by time of day',
            disabled = true
        }
    }
    
    local hour = tonumber(os.date('%H'))
    local timeOfDay = 'Afternoon'
    
    for _, period in pairs(Config.TimePricing) do
        if hour >= period.start and hour < period.endTime then
            timeOfDay = period.name or 'Unknown'
            break
        end
    end
    
    table.insert(options, {
        title = 'Time: ' .. timeOfDay,
        description = os.date('%H:%M'),
        disabled = true
    })
    
    table.insert(options, {
        title = '---',
        disabled = true
    })
    
    for drugType, basePrice in pairs(Config.MarketPrices) do
        local prodConfig = Config.ProductionTypes[drugType]
        table.insert(options, {
            title = prodConfig.label,
            description = 'Street: ' .. Utils.formatMoney(basePrice) .. '/g | Black Market: ' .. Utils.formatMoney(Config.BlackMarketPrices[drugType]) .. '/g',
            disabled = true
        })
    end
    
    lib.registerContext({
        id = 'market_prices_menu',
        title = 'Market Prices',
        menu = 'market_menu',
        options = options
    })
    
    lib.showContext('market_prices_menu')
end)

-- My operations
RegisterNetEvent('dea-cartel:client:showMyOperations', function()
    local playerID = GetPlayerServerId(PlayerId())
    local owned = {}
    
    for opID, op in pairs(ClientOperations) do
        if op.owner == playerID then
            table.insert(owned, opID)
        end
    end
    
    if #owned == 0 then
        lib.notify({
            title = 'No Operations',
            description = 'You don\'t own any operations',
            type = 'info',
            duration = 3000
        })
        return
    end
    
    local options = {}
    for _, opID in ipairs(owned) do
        local op = ClientOperations[opID]
        table.insert(options, {
            title = 'Operation #' .. opID,
            description = op.type .. ' - ' .. op.productionType .. ' (' .. op.status .. ')',
            onSelect = function()
                ShowOperationMenu(opID)
            end
        })
    end
    
    lib.registerContext({
        id = 'my_operations_menu',
        title = 'My Operations',
        menu = 'criminal_main_menu',
        options = options
    })
    
    lib.showContext('my_operations_menu')
end)

-- Nearby operations
RegisterNetEvent('dea-cartel:client:showNearbyOperations', function()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local nearby = {}
    
    for opID, op in pairs(ClientOperations) do
        local distance = #(playerCoords - op.coords)
        if distance < 200 then
            table.insert(nearby, { id = opID, distance = distance })
        end
    end
    
    if #nearby == 0 then
        lib.notify({
            title = 'None Nearby',
            description = 'No operations found within 200m',
            type = 'info',
            duration = 3000
        })
        return
    end
    
    table.sort(nearby, function(a, b) return a.distance < b.distance end)
    
    local options = {}
    for _, item in ipairs(nearby) do
        local op = ClientOperations[item.id]
        table.insert(options, {
            title = 'Operation #' .. item.id,
            description = op.type .. ' (' .. math.floor(item.distance) .. 'm)',
            onSelect = function()
                ShowOperationMenu(item.id)
            end
        })
    end
    
    lib.registerContext({
        id = 'nearby_operations_menu',
        title = 'Nearby Operations',
        menu = 'criminal_main_menu',
        options = options
    })
    
    lib.showContext('nearby_operations_menu')
end)

-- Hideout menu
RegisterNetEvent('dea-cartel:client:openHideoutMenu', function()
    local options = {
        {
            title = 'Safe Houses',
            description = 'Find hideouts and install defenses',
            disabled = true
        }
    }
    
    for _, hideout in ipairs(Config.Hideouts) do
        table.insert(options, {
            title = hideout.name,
            description = 'Capacity: ' .. hideout.capacity .. ' | Security: ' .. string.format('%.0f%%', hideout.heatReduction * 100),
            icon = hideout.icon,
            arrow = true,
            onSelect = function()
                ShowHideoutMenu(hideout)
            end
        })
    end
    
    lib.registerContext({
        id = 'hideout_main_menu',
        title = 'Safe Houses',
        menu = 'criminal_main_menu',
        options = options
    })
    
    lib.showContext('hideout_main_menu')
end)

-- Survival menu (bribery, informants, evasion)
RegisterNetEvent('dea-cartel:client:openSurvivalMenu', function()
    local options = {
        {
            title = 'Survive & Thrive',
            description = 'Counter DEA operations',
            disabled = true
        },
        {
            title = 'Bribe Agent',
            description = 'Pay DEA agent to look away',
            icon = 'fas fa-money-bill',
            onSelect = function()
                ShowBriberyMenu()
            end
        },
        {
            title = 'Recruit Informant',
            description = 'Get inside DEA intelligence',
            icon = 'fas fa-user-secret',
            onSelect = function()
                ShowInformantMenu()
            end
        },
        {
            title = 'Raid Response',
            description = 'Evade or defend incoming raids',
            icon = 'fas fa-shield-halved',
            onSelect = function()
                ShowRaidEvadeMenu()
            end
        },
        {
            title = 'Check Heat',
            description = 'View your current heat level',
            icon = 'fas fa-thermometer-half',
            onSelect = function()
                lib.notify({
                    title = 'Heat Level',
                    description = math.floor(ClientHeatLevel) .. '/100',
                    type = 'info',
                    duration = 3000
                })
            end
        }
    }
    
    lib.registerContext({
        id = 'survival_menu',
        title = 'Survive & Thrive',
        menu = 'criminal_main_menu',
        options = options
    })
    
    lib.showContext('survival_menu')
end)

-- ========== DEA MENU ==========

RegisterNetEvent('dea-cartel:client:openDEAMenu', function()
    local player = QBCore.GetPlayerData()
    
    if player.job.name ~= 'police' then
        lib.notify({
            title = 'Error',
            description = 'You are not DEA',
            type = 'error',
            duration = 3000
        })
        return
    end
    
    local options = {
        {
            title = 'DEA Operations',
            description = 'Crime prevention tools - Grade: ' .. player.job.grade,
            disabled = true
        },
        {
            title = 'Operations Dashboard',
            description = 'View active investigations',
            icon = 'fas fa-chart-bar',
            onSelect = function()
                OpenDEADashboard()
            end
        }
    }
    
    if player.job.grade >= 2 then
        table.insert(options, {
            title = 'Surveillance Tools',
            description = 'Drone, GPS, drug tests',
            icon = 'fas fa-satellite',
            arrow = true,
            onSelect = function()
                OpenSurveillanceMenu(player.job.grade)
            end
        })
    end
    
    if player.job.grade >= 4 then
        table.insert(options, {
            title = 'Raid Operations',
            description = 'Execute warrants',
            icon = 'fas fa-burst',
            arrow = true,
            onSelect = function()
                OpenRaidMenu()
            end
        })
    end
    
    if player.job.grade >= 1 then
        table.insert(options, {
            title = 'Make Arrest',
            description = 'Arrest and process',
            icon = 'fas fa-handcuffs',
            arrow = true,
            onSelect = function()
                OpenArrestMenu()
            end
        })
    end
    
    lib.registerContext({
        id = 'dea_main_menu',
        title = 'DEA Operations',
        options = options
    })
    
    lib.showContext('dea_main_menu')
end)

function OpenDEADashboard()
    local options = {
        {
            title = 'Active Cases',
            description = 'Ongoing investigations',
            disabled = true
        },
        {
            title = 'Heat Tracker',
            description = 'Monitor suspect heat levels',
            icon = 'fas fa-thermometer-half',
            onSelect = function()
                lib.notify({
                    title = 'Heat Tracking',
                    description = 'Use /addplayerheat [playerID] [amount] to add heat',
                    type = 'info',
                    duration = 5000
                })
            end
        },
        {
            title = 'Active Raids',
            description = 'View ongoing operations',
            icon = 'fas fa-fire',
            onSelect = function()
                lib.notify({
                    title = 'Active Raids',
                    description = 'No active raids',
                    type = 'info',
                    duration = 3000
                })
            end
        }
    }
    
    lib.registerContext({
        id = 'dea_dashboard',
        title = 'Operations Dashboard',
        menu = 'dea_main_menu',
        options = options
    })
    
    lib.showContext('dea_dashboard')
end

print('^2[DEA-Cartel] ^7Comprehensive interaction system loaded^0')
