local QBCore = exports['qb-core']:GetCoreObject()

-- Track DEA operations
DEAOperations = {}  -- Active DEA tasks
PlayerHeatLevels = {}  -- { playerID = { heat = 0, lastEvent = 0 } }
PropertyHeatLevels = {}  -- { propertyID = { heat = 0, lastEvent = 0 } }
ActiveDroneControllers = {}  -- { playerID = droneID }
GPSTrackers = {}  -- { trackerID = { targetVehicle, installTime, ... } }
ArrestedPlayers = {}  -- { playerID = { chargeType, arrestTime, ... } }

-- Check if player is DEA
function IsPlayerDEA(source)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false end
    
    if player.PlayerData.job.name ~= Config.DEA.jobName then
        return false
    end
    
    return true
end

-- Check DEA permission level
function GetDEAPermission(source, permission)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false end
    
    if player.PlayerData.job.name ~= Config.DEA.jobName then
        return false
    end
    
    local rank = Config.DEA.ranks[player.PlayerData.job.grade] or Config.DEA.ranks.trainee
    
    if permission == 'arrest' then
        return rank.canArrest
    elseif permission == 'surveillance' then
        return rank.canSurveillance
    elseif permission == 'raid' then
        return rank.canRaid
    end
    
    return false
end

-- Add heat to player
function AddPlayerHeat(source, amount, reason)
    if not PlayerHeatLevels[source] then
        PlayerHeatLevels[source] = { heat = 0, lastEvent = os.time(), events = {} }
    end
    
    local heatData = PlayerHeatLevels[source]
    heatData.heat = math.min(heatData.heat + amount, Config.HeatSystem.playerHeat.maxHeat)
    heatData.lastEvent = os.time()
    
    table.insert(heatData.events, {
        reason = reason,
        amount = amount,
        timestamp = os.time()
    })
    
    -- Check if reached raid threshold
    if heatData.heat >= Config.HeatSystem.thresholds.raid then
        TriggerHeatAlert(source, heatData.heat, reason)
    end
    
    local player = QBCore.Functions.GetPlayer(source)
    if player then
        player.Functions.Notify('Heat Level: ' .. math.floor(heatData.heat) .. '/100', 'info', 3000)
    end
    
    TriggerClientEvent('dea-cartel:client:updateHeatLevel', source, heatData.heat)
    
    return heatData.heat
end

-- Trigger heat alert for DEA
function TriggerHeatAlert(playerID, heatLevel, reason)
    -- Notify all DEA agents
    for _, agentID in ipairs(GetPlayers()) do
        local agent = QBCore.Functions.GetPlayer(tonumber(agentID))
        if agent and agent.PlayerData.job.name == Config.DEA.jobName then
            agent.Functions.Notify('ALERT: Target heat level ' .. math.floor(heatLevel) .. ' - ' .. reason, 'error', 5000)
        end
    end
end

-- Start drone surveillance
function StartDroneSurveillance(source, targetPlayerID)
    if not GetDEAPermission(source, 'surveillance') then
        return { success = false, message = 'You do not have surveillance permissions' }
    end
    
    if ActiveDroneControllers[source] then
        return { success = false, message = 'You already have an active drone' }
    end
    
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return { success = false, message = 'Player not found' } end
    
    local droneID = 'drone_' .. source .. '_' .. os.time()
    
    ActiveDroneControllers[source] = droneID
    
    DEAOperations[droneID] = {
        id = droneID,
        type = 'drone',
        operator = source,
        operatorName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
        targetPlayer = targetPlayerID,
        startTime = os.time(),
        flightTime = Config.SurveillanceTools.drone.flightTime,
        evidence = {},
        active = true
    }
    
    TriggerClientEvent('dea-cartel:client:startDroneSurveillance', source, {
        droneID = droneID,
        targetPlayer = targetPlayerID,
        flightTime = Config.SurveillanceTools.drone.flightTime
    })
    
    player.Functions.Notify('Drone surveillance started', 'success', 3000)
    
    return { success = true, droneID = droneID }
end

-- Plant GPS tracker on vehicle
function PlantGPSTracker(source, vehicleNetID)
    if not GetDEAPermission(source, 'surveillance') then
        return { success = false, message = 'You do not have surveillance permissions' }
    end
    
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return { success = false, message = 'Player not found' } end
    
    -- Count active trackers
    local activeCount = 0
    for _, tracker in pairs(GPSTrackers) do
        if tracker.operator == source and tracker.active then
            activeCount = activeCount + 1
        end
    end
    
    if activeCount >= Config.SurveillanceTools.gpsTracker.maxActive then
        return { success = false, message = 'Max active trackers reached' }
    end
    
    local trackerID = 'tracker_' .. source .. '_' .. os.time()
    
    GPSTrackers[trackerID] = {
        id = trackerID,
        operator = source,
        operatorName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
        vehicleNetID = vehicleNetID,
        installTime = os.time(),
        expiryTime = os.time() + Config.SurveillanceTools.gpsTracker.duration,
        active = true,
        detected = false
    }
    
    player.Functions.Notify('GPS tracker planted. Duration: ' .. Config.SurveillanceTools.gpsTracker.duration / 60000 .. ' minutes', 'success', 3000)
    
    return { success = true, trackerID = trackerID }
end

-- Test drug substance
function TestDrugSubstance(source, drugType)
    if not GetDEAPermission(source, 'surveillance') then
        return { success = false, message = 'You do not have test kit access' }
    end
    
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return { success = false, message = 'Player not found' } end
    
    if not Config.ProductionTypes[drugType] then
        return { success = false, message = 'Invalid drug type' }
    end
    
    player.Functions.Notify('Testing ' .. Config.ProductionTypes[drugType].label .. '...', 'info', 3000)
    
    -- Test takes time, client will handle the progress
    TriggerClientEvent('dea-cartel:client:performDrugTest', source, drugType)
    
    return { success = true, message = 'Test in progress' }
end

-- Initiate raid on property
function InitiateRaid(source, targetPlayerID, propertyCoords, evidence)
    if not GetDEAPermission(source, 'raid') then
        return { success = false, message = 'You do not have raid permissions' }
    end
    
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return { success = false, message = 'Player not found' } end
    
    if not PlayerHeatLevels[targetPlayerID] or PlayerHeatLevels[targetPlayerID].heat < Config.RaidMechanics.minHeatForRaid then
        return { success = false, message = 'Insufficient heat level for raid' }
    end
    
    local raidID = 'raid_' .. source .. '_' .. os.time()
    
    DEAOperations[raidID] = {
        id = raidID,
        type = 'raid',
        operator = source,
        operatorName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
        targetPlayer = targetPlayerID,
        location = propertyCoords,
        startTime = os.time(),
        status = 'executing',
        seized = {
            cash = 0,
            drugs = {},
            equipment = {}
        },
        evidence = evidence or {}
    }
    
    -- Notify all nearby players of raid
    TriggerClientEvent('dea-cartel:client:radarRaidAlert', -1, propertyCoords)
    
    player.Functions.Notify('RAID INITIATED', 'error', 5000)
    
    return {
        success = true,
        raidID = raidID,
        message = 'Raid in progress'
    }
end

-- Complete raid and seize items
function CompleteRaid(source, raidID, seizedItems)
    if not DEAOperations[raidID] then
        return { success = false, message = 'Raid not found' }
    end
    
    local raid = DEAOperations[raidID]
    local operator = QBCore.Functions.GetPlayer(source)
    if not operator then return { success = false, message = 'Operator not found' } end
    
    local target = QBCore.Functions.GetPlayer(raid.targetPlayer)
    if not target then return { success = false, message = 'Target not found' } end
    
    -- Seize cash
    local cashSeized = math.floor(target.PlayerData.money.cash * Config.RaidMechanics.seizures.cash)
    target.Functions.RemoveMoney('cash', cashSeized)
    raid.seized.cash = cashSeized
    
    -- Seize items
    for itemName, amount in pairs(seizedItems or {}) do
        if target.Functions.HasItem(itemName, amount) then
            target.Functions.RemoveItem(itemName, amount)
            raid.seized.drugs[itemName] = amount
        end
    end
    
    -- Give DEA bonuses
    local totalValue = cashSeized + (table.concat(raid.seized.drugs or {}) * 10)  -- Estimate drug value
    local operatorBonus = Config.RaidMechanics.rewards.raidBonus + totalValue
    
    operator.Functions.AddMoney('cash', operatorBonus)
    operator.Functions.Notify('Raid complete! Seized: ' .. Utils.formatMoney(cashSeized), 'success', 5000)
    
    -- Notify target
    target.Functions.Notify('Your property was raided by DEA', 'error', 7000)
    
    raid.status = 'completed'
    raid.completedTime = os.time()
    
    return {
        success = true,
        seized = raid.seized,
        bonus = operatorBonus
    }
end

-- Arrest a player
function ArrestPlayer(source, targetPlayerID, chargeType)
    if not GetDEAPermission(source, 'arrest') then
        return { success = false, message = 'You do not have arrest permissions' }
    end
    
    local operator = QBCore.Functions.GetPlayer(source)
    local target = QBCore.Functions.GetPlayer(targetPlayerID)
    
    if not operator or not target then
        return { success = false, message = 'Player not found' }
    end
    
    if not Config.Arrests.charges[chargeType] then
        return { success = false, message = 'Invalid charge type' }
    end
    
    local chargeData = Config.Arrests.charges[chargeType]
    local arrestID = 'arrest_' .. source .. '_' .. os.time()
    
    ArrestedPlayers[targetPlayerID] = {
        id = arrestID,
        arrestor = source,
        arrestorName = operator.PlayerData.charinfo.firstname .. ' ' .. operator.PlayerData.charinfo.lastname,
        charge = chargeType,
        bail = chargeData.bail,
        jailTime = chargeData.jail,
        arrestTime = os.time(),
        processed = false
    }
    
    -- Give operator bonus
    operator.Functions.AddMoney('cash', Config.DEA.payouts.arrest)
    operator.Functions.Notify('Arrested ' .. target.PlayerData.charinfo.firstname, 'success', 3000)
    
    -- Notify target
    target.Functions.Notify('You have been arrested for ' .. chargeType, 'error', 5000)
    TriggerClientEvent('dea-cartel:client:arrested', targetPlayerID, {
        chargeType = chargeType,
        bail = chargeData.bail,
        jailTime = chargeData.jail
    })
    
    return {
        success = true,
        arrestID = arrestID,
        charge = chargeType,
        bail = chargeData.bail
    }
end

-- Heat decay loop
CreateThread(function()
    while true do
        Wait(Config.HeatSystem.playerHeat.decayInterval)
        
        -- Decay player heat
        for playerID, heatData in pairs(PlayerHeatLevels) do
            local decayAmount = Config.HeatSystem.playerHeat.decayRate
            heatData.heat = math.max(0, heatData.heat - decayAmount)
            
            local player = QBCore.Functions.GetPlayer(tonumber(playerID))
            if player then
                TriggerClientEvent('dea-cartel:client:updateHeatLevel', tonumber(playerID), heatData.heat)
            end
        end
        
        -- Clean up expired trackers
        for trackerID, tracker in pairs(GPSTrackers) do
            if tracker.active and os.time() > tracker.expiryTime then
                tracker.active = false
            end
        end
    end
end)

-- Network events
RegisterNetEvent('dea-cartel:server:startDroneSurveillance', function(targetPlayerID)
    local result = StartDroneSurveillance(source, targetPlayerID)
    TriggerClientEvent('dea-cartel:client:operationResult', source, result)
end)

RegisterNetEvent('dea-cartel:server:plantGPSTracker', function(vehicleNetID)
    local result = PlantGPSTracker(source, vehicleNetID)
    TriggerClientEvent('dea-cartel:client:operationResult', source, result)
end)

RegisterNetEvent('dea-cartel:server:testDrug', function(drugType)
    local result = TestDrugSubstance(source, drugType)
    TriggerClientEvent('dea-cartel:client:operationResult', source, result)
end)

RegisterNetEvent('dea-cartel:server:initiateRaid', function(targetPlayerID, coords, evidence)
    local result = InitiateRaid(source, targetPlayerID, coords, evidence)
    TriggerClientEvent('dea-cartel:client:operationResult', source, result)
end)

RegisterNetEvent('dea-cartel:server:completeRaid', function(raidID, seizedItems)
    local result = CompleteRaid(source, raidID, seizedItems)
    TriggerClientEvent('dea-cartel:client:operationResult', source, result)
end)

RegisterNetEvent('dea-cartel:server:arrestPlayer', function(targetPlayerID, chargeType)
    local result = ArrestPlayer(source, targetPlayerID, chargeType)
    TriggerClientEvent('dea-cartel:client:operationResult', source, result)
end)

print('^2[DEA-Cartel] ^7DEA mechanics initialized^0')
