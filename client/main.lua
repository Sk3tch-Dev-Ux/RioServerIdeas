local QBCore = exports['qb-core']:GetCoreObject()
local lib = exports.ox_lib

-- Client-side operation cache
ClientOperations = {}
PlayerData = {}
TargetZones = {}

-- Update player data on spawn
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.GetPlayerData()
    lib.notify({
        title = 'DEA vs Cartel',
        description = 'System initialized',
        type = 'success',
        duration = 3000
    })
    print('^2[DEA-Cartel] ^7Player loaded^0')
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
end)

-- Sync operations from server
RegisterNetEvent('dea-cartel:client:syncOperations', function(operations)
    ClientOperations = operations
    UpdateTargetZones()
end)

-- Handle operation results (notifications)
RegisterNetEvent('dea-cartel:client:operationResult', function(result)
    if result.success then
        lib.notify({
            title = 'Success',
            description = result.message,
            type = 'success',
            duration = 3000
        })
    else
        lib.notify({
            title = 'Error',
            description = result.message,
            type = 'error',
            duration = 3000
        })
    end
end)

-- Handle operation status
RegisterNetEvent('dea-cartel:client:operationStatus', function(result)
    if result.success then
        local op = result.operation
        lib.notify({
            title = 'Operation #' .. op.id,
            description = op.ownerName .. '\nStatus: ' .. op.status,
            type = 'info',
            duration = 5000
        })
    else
        lib.notify({
            title = 'Error',
            description = result.message,
            type = 'error',
            duration = 3000
        })
    end
end)

-- Show operation details in ox_lib context menu
function ShowOperationMenu(opID)
    local op = ClientOperations[opID]
    if not op then return end
    
    local options = {
        {
            title = 'Owner: ' .. op.ownerName,
            description = 'Cannot be changed',
            disabled = true
        },
        {
            title = 'Type: ' .. op.type,
            description = 'Operation type',
            disabled = true
        },
        {
            title = 'Production: ' .. Config.ProductionTypes[op.productionType].label,
            description = 'What is being produced',
            disabled = true
        },
        {
            title = 'Status: ' .. op.status,
            description = 'Current operation status',
            disabled = true
        },
    }
    
    -- Add action buttons if player owns operation
    if op.owner == GetPlayerServerId(PlayerId()) then
        if op.status == 'idle' or op.status == 'ready' then
            table.insert(options, {
                title = 'Resupply',
                description = 'Cost: ' .. Utils.formatMoney(Utils.getSupplyCost(op.productionType)),
                icon = 'fas fa-dolly',
                onSelect = function()
                    TriggerServerEvent('dea-cartel:server:resupply', opID)
                end
            })
        end
        
        if (op.status == 'idle' or op.status == 'ready') and (op.supplies.level or 0) > 0 then
            table.insert(options, {
                title = 'Start Production',
                description = 'Begin ' .. Config.ProductionTypes[op.productionType].label .. ' production',
                icon = 'fas fa-play',
                onSelect = function()
                    TriggerServerEvent('dea-cartel:server:startProduction', opID)
                    lib.notify({
                        title = 'Production Started',
                        description = 'Estimated time: ' .. math.ceil(Config.ProductionTypes[op.productionType].productionTime / 60000) .. ' minutes',
                        type = 'info',
                        duration = 4000
                    })
                end
            })
        end
        
        if op.status == 'ready' then
            table.insert(options, {
                title = 'Collect Production',
                description = 'Yield: ' .. op.production.currentYield .. 'g | Quality: ' .. string.format('%.2f', op.production.quality),
                icon = 'fas fa-box',
                onSelect = function()
                    TriggerServerEvent('dea-cartel:server:collectProduction', opID)
                end
            })
        end
        
        -- Grow house specific options
        if op.type == 'growhouse' then
            table.insert(options, {
                title = 'Plant Seeds',
                description = 'Add plants to grow house',
                icon = 'fas fa-leaf',
                onSelect = function()
                    PlantSeedAtOp(opID)
                end
            })
            
            table.insert(options, {
                title = 'Harvest Plants',
                description = 'Harvest mature plants',
                icon = 'fas fa-hand',
                onSelect = function()
                    HarvestPlantsAtOp(opID)
                end
            })
            
            table.insert(options, {
                title = 'Manage Upgrades',
                description = 'Buy grow house upgrades',
                icon = 'fas fa-hammer',
                onSelect = function()
                    ManageGrowUpgrades(opID)
                end
            })
        end
    end
    
    lib.registerContext({
        id = 'operation_menu_' .. opID,
        title = 'Operation #' .. opID,
        options = options
    })
    
    lib.showContext('operation_menu_' .. opID)
end

-- Setup operation at location
function OpenCreateOperationMenu()
    local options = {}
    
    -- Add operation type options
    for opType, opConfig in pairs(Config.OperationTypes) do
        table.insert(options, {
            title = opConfig.label,
            description = 'Setup: ' .. Utils.formatMoney(0),
            icon = opConfig.icon,
            args = opType,
            arrow = true
        })
    end
    
    lib.registerContext({
        id = 'create_operation_menu',
        title = 'Setup Operation',
        options = options,
        onSelect = function(data)
            OpenProductionTypeMenu(data.args)
        end
    })
    
    lib.showContext('create_operation_menu')
end

function OpenProductionTypeMenu(opType)
    local opConfig = Config.OperationTypes[opType]
    local options = {}
    
    for _, prodType in ipairs(opConfig.productionTypes) do
        local prodConfig = Config.ProductionTypes[prodType]
        table.insert(options, {
            title = prodConfig.label,
            description = 'Setup Cost: ' .. Utils.formatMoney(prodConfig.setupCost),
            icon = prodConfig.icon,
            onSelect = function()
                local coords = GetEntityCoords(PlayerPedId())
                TriggerServerEvent('dea-cartel:server:createOperation', opType, prodType, coords)
            end
        })
    end
    
    lib.registerContext({
        id = 'production_type_menu_' .. opType,
        title = 'Select Production Type',
        menu = 'create_operation_menu',
        options = options
    })
    
    lib.showContext('production_type_menu_' .. opType)
end

-- Sell drugs dialog
function OpenSellDrugsMenu()
    local options = {}
    
    for prodType, prodConfig in pairs(Config.ProductionTypes) do
        table.insert(options, {
            title = prodConfig.label,
            description = 'Base Price: ' .. Utils.formatMoney(Config.MarketPrices[prodType]) .. '/g',
            icon = prodConfig.icon,
            args = prodType,
            arrow = true
        })
    end
    
    lib.registerContext({
        id = 'sell_drugs_menu',
        title = 'Sell Drugs',
        options = options,
        onSelect = function(data)
            OpenSellAmountDialog(data.args)
        end
    })
    
    lib.showContext('sell_drugs_menu')
end

function OpenSellAmountDialog(drugType)
    local input = lib.inputDialog('Sell ' .. Config.ProductionTypes[drugType].label, {
        { type = 'number', label = 'Amount (grams)', description = 'How much to sell?', required = true, min = 1 }
    })
    
    if input then
        local amount = input[1]
        TriggerServerEvent('dea-cartel:server:sellDrugs', drugType, amount)
    end
end

-- Update target zones for all operations
function UpdateTargetZones()
    -- Remove old zones
    for _, zoneId in ipairs(TargetZones) do
        exports.ox_target:removeZone(zoneId)
    end
    TargetZones = {}
    
    -- Create new zones for each operation
    for opID, op in pairs(ClientOperations) do
        local zoneId = exports.ox_target:addSphereZone({
            coords = op.coords,
            radius = 5.0,
            debug = false,
            options = {
                {
                    name = 'operation_info_' .. opID,
                    label = 'View Operation',
                    icon = 'fas fa-info-circle',
                    distance = 5.0,
                    onSelect = function()
                        ShowOperationMenu(opID)
                    end
                }
            }
        })
        table.insert(TargetZones, zoneId)
    end
end

-- Spawn dealer NPCs
CreateThread(function()
    Wait(1000)
    
    -- Spawn each dealer
    for dealerID, dealerData in ipairs(Config.Dealers) do
        SpawnDealer(dealerID, dealerData)
    end
end)

-- Spawn single dealer NPC
function SpawnDealer(dealerID, dealerData)
    local model = GetHashKey(dealerData.model)
    
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 5000 do
        Wait(100)
        timeout = timeout + 100
    end
    
    if not HasModelLoaded(model) then return end
    
    local ped = CreatePed(4, model, dealerData.coords.x, dealerData.coords.y, dealerData.coords.z, dealerData.heading, true, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    
    -- Add target option to this ped
    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'talk_dealer_' .. dealerID,
            label = 'Talk to Dealer',
            icon = 'fas fa-handshake',
            distance = 3.0,
            onSelect = function()
                ShowDealerMenu(dealerID, dealerData)
            end
        }
    })
end

-- Show dealer menu
function ShowDealerMenu(dealerID, dealerData)
    local options = {
        {
            title = dealerData.name,
            description = 'Street drug dealer',
            disabled = true
        }
    }
    
    -- List available drug types
    for _, tier in ipairs(dealerData.tiers) do
        local prodConfig = Config.ProductionTypes[tier.drugType]
        table.insert(options, {
            title = 'Sell ' .. prodConfig.label,
            description = 'Max: ' .. tier.maxQuantity .. 'g | Price: ' .. string.format('%.0f%%', tier.minPayment * 100) .. '-' .. string.format('%.0f%%', tier.maxPayment * 100),
            icon = prodConfig.icon,
            args = { dealerID = dealerID, drugType = tier.drugType, maxQuantity = tier.maxQuantity },
            onSelect = function(data)
                OpenDealerSellDialog(data.args)
            end
        })
    end
    
    lib.registerContext({
        id = 'dealer_menu_' .. dealerID,
        title = dealerData.name,
        options = options
    })
    
    lib.showContext('dealer_menu_' .. dealerID)
end

-- Sell to dealer dialog
function OpenDealerSellDialog(dealerInfo)
    local input = lib.inputDialog('Sell to ' .. Config.Dealers[dealerInfo.dealerID].name, {
        { type = 'number', label = Config.ProductionTypes[dealerInfo.drugType].label .. ' (grams)', description = 'Max: ' .. dealerInfo.maxQuantity .. 'g', required = true, min = 1, max = dealerInfo.maxQuantity }
    })
    
    if input then
        local amount = input[1]
        TriggerServerEvent('dea-cartel:server:sellToDealer', dealerInfo.dealerID, dealerInfo.drugType, amount)
    end
end

-- Show bulk sale routes menu
function OpenBulkSaleMenu()
    local options = {
        {
            title = 'Bulk Drug Delivery',
            description = 'Transport large quantities via vehicle',
            disabled = true
        }
    }
    
    for _, route in ipairs(Config.BulkSaleRoutes) do
        table.insert(options, {
            title = route.name,
            description = 'Vehicle: ' .. route.vehicleType .. ' | Min: ' .. route.minQuantity .. 'g | Base: ' .. Utils.formatMoney(route.reward),
            icon = 'fas fa-truck',
            args = route.id,
            arrow = true,
            onSelect = function(data)
                OpenBulkSaleDrugMenu(data.args)
            end
        })
    end
    
    lib.registerContext({
        id = 'bulk_sale_menu',
        title = 'Bulk Delivery Routes',
        options = options
    })
    
    lib.showContext('bulk_sale_menu')
end

-- Select drug type for bulk sale
function OpenBulkSaleDrugMenu(routeID)
    local route = nil
    for _, r in ipairs(Config.BulkSaleRoutes) do
        if r.id == routeID then
            route = r
            break
        end
    end
    
    if not route then return end
    
    local options = {}
    for prodType, _ in pairs(Config.ProductionTypes) do
        local prodConfig = Config.ProductionTypes[prodType]
        table.insert(options, {
            title = prodConfig.label,
            description = 'Min: ' .. route.minQuantity .. 'g',
            icon = prodConfig.icon,
            args = { routeID = routeID, drugType = prodType },
            onSelect = function(data)
                OpenBulkSaleQuantityDialog(data.args, route.minQuantity)
            end
        })
    end
    
    lib.registerContext({
        id = 'bulk_drug_menu_' .. routeID,
        title = 'Select Drug Type',
        menu = 'bulk_sale_menu',
        options = options
    })
    
    lib.showContext('bulk_drug_menu_' .. routeID)
end

-- Enter quantity for bulk sale
function OpenBulkSaleQuantityDialog(saleInfo, minQuantity)
    local input = lib.inputDialog('Bulk Sale - ' .. Config.ProductionTypes[saleInfo.drugType].label, {
        { type = 'number', label = 'Amount (grams)', description = 'Minimum: ' .. minQuantity .. 'g', required = true, min = minQuantity }
    })
    
    if input then
        local amount = input[1]
        TriggerServerEvent('dea-cartel:server:startBulkSale', saleInfo.routeID, saleInfo.drugType, amount)
    end
end

-- Global hotkey menu
CreateThread(function()
    Wait(500)
    
    -- Main menu hotkey (F6 - handled in interactions.lua)
    -- Additional context menu on right-click for quick access
    exports.ox_target:addGlobalOption({
        name = 'open_main_menu',
        label = 'Criminal Menu (F6)',
        icon = 'fas fa-bars',
        distance = 100.0,
        canInteract = function()
            return true
        end,
        onSelect = function()
            TriggerEvent('dea-cartel:client:openMainMenu')
        end
    })
end)

-- Initial sync
CreateThread(function()
    Wait(1000)
    UpdateTargetZones()
end)

print('^2[DEA-Cartel] ^7Client initialized^0')
