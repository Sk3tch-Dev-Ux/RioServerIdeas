local QBCore = exports['qb-core']:GetCoreObject()
local lib = exports.ox_lib

-- Client DEA tracking
ClientHeatLevel = 0
ActiveDrone = nil
ActiveTrackers = {}
IsArmed = false

-- Heat level updates
RegisterNetEvent('dea-cartel:client:updateHeatLevel', function(heatLevel)
    ClientHeatLevel = heatLevel
    
    -- Visual feedback based on heat
    if heatLevel > 85 then
        TriggerScreenEffect("DeathFailOut", 1000)
    elseif heatLevel > 70 then
        TriggerScreenEffect("RaceTurbo", 500)
    end
end)

-- Raid alert with radar blip
RegisterNetEvent('dea-cartel:client:radarRaidAlert', function(coords)
    -- Play alarm sound
    PlaySoundFrontend(-1, "CONFIRM_BEEP", "HUD_MINI_GAME_SOUNDSET", true)
    
    lib.notify({
        title = 'RAID IN PROGRESS',
        description = 'DEA raid detected at nearby location',
        type = 'error',
        duration = 5000
    })
    
    -- Add blip
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 227)  -- Raid icon
    SetBlipColour(blip, 1)  -- Red
    SetBlipRoute(blip, true)
    
    -- Remove after 10 minutes
    SetTimeout(600000, function()
        RemoveBlip(blip)
    end)
end)

-- Arrest notification
RegisterNetEvent('dea-cartel:client:arrested', function(arrestData)
    lib.notify({
        title = 'ARRESTED',
        description = 'Charge: ' .. arrestData.chargeType .. '\nBail: ' .. Utils.formatMoney(arrestData.bail),
        type = 'error',
        duration = 7000
    })
    
    -- Fade out screen (jail time)
    DoScreenFadeOut(1000)
    Wait(arrestData.jailTime)
    DoScreenFadeIn(1000)
end)

-- Start drone surveillance operation
RegisterNetEvent('dea-cartel:client:startDroneSurveillance', function(droneData)
    ActiveDrone = droneData.droneID
    
    lib.notify({
        title = 'Drone Active',
        description = 'Flight time: ' .. droneData.flightTime / 60000 .. ' minutes',
        type = 'info',
        duration = 4000
    })
    
    -- Start drone flight time countdown
    CreateThread(function()
        local startTime = os.time()
        while ActiveDrone == droneData.droneID and os.time() - startTime < droneData.flightTime / 1000 do
            Wait(1000)
        end
        
        lib.notify({
            title = 'Drone',
            description = 'Flight time expired',
            type = 'warning',
            duration = 3000
        })
        ActiveDrone = nil
    end)
end)

-- Perform drug test
RegisterNetEvent('dea-cartel:client:performDrugTest', function(drugType)
    local testTime = Config.SurveillanceTools.drugTest.testTime / 1000
    
    lib.notify({
        title = 'Testing ' .. Config.ProductionTypes[drugType].label,
        description = 'Test in progress (' .. testTime .. 's)',
        type = 'info',
        duration = testTime * 1000
    })
    
    lib.progressBar({
        duration = testTime * 1000,
        label = 'Testing substance...',
        useWhileDead = false,
        canCancel = false,
        disable = {
            car = true,
            move = true,
            combat = true
        }
    })
    
    lib.notify({
        title = 'Test Results',
        description = 'Substance identified as ' .. Config.ProductionTypes[drugType].label,
        type = 'success',
        duration = 5000
    })
end)

-- DEA Menu for police job members
function OpenDEAMenu()
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
            description = 'Crime prevention tools',
            disabled = true
        }
    }
    
    -- Surveillance options (Agent+)
    if player.job.grade >= 2 then
        table.insert(options, {
            title = 'Surveillance Tools',
            description = 'Drone, GPS, wiretap',
            icon = 'fas fa-satellite',
            arrow = true,
            onSelect = function()
                OpenSurveillanceMenu(player.job.grade)
            end
        })
    end
    
    -- Raid options (Supervisor+)
    if player.job.grade >= 4 then
        table.insert(options, {
            title = 'Initiate Raid',
            description = 'Execute warrant on property',
            icon = 'fas fa-burst',
            arrow = true,
            onSelect = function()
                OpenRaidMenu()
            end
        })
    end
    
    -- Arrest options (Officer+)
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
    
    -- Heat tracking
    table.insert(options, {
        title = 'Heat Level Tracker',
        description = 'Monitor suspect heat',
        icon = 'fas fa-thermometer-half',
        onSelect = function()
            OpenHeatTracker()
        end
    })
    
    lib.registerContext({
        id = 'dea_main_menu',
        title = 'DEA Operations',
        options = options
    })
    
    lib.showContext('dea_main_menu')
end

-- Surveillance tools menu
function OpenSurveillanceMenu(grade)
    local options = {
        {
            title = 'Surveillance Tools',
            description = 'Monitor suspects',
            disabled = true
        },
        {
            title = 'Deploy Drone',
            description = 'Aerial reconnaissance',
            icon = 'fas fa-plane',
            onSelect = function()
                OpenDroneMenu()
            end
        },
        {
            title = 'Plant GPS Tracker',
            description = 'Vehicle tracking device',
            icon = 'fas fa-location-dot',
            onSelect = function()
                OpenGPSMenu()
            end
        },
        {
            title = 'Drug Test Kit',
            description = 'Test substances',
            icon = 'fas fa-vial',
            onSelect = function()
                OpenDrugTestMenu()
            end
        }
    }
    
    if grade >= 3 then
        table.insert(options, {
            title = 'Install Wiretap',
            description = 'Monitor communications',
            icon = 'fas fa-phone',
            onSelect = function()
                OpenWiretapMenu()
            end
        })
    end
    
    lib.registerContext({
        id = 'surveillance_menu',
        title = 'Surveillance Tools',
        menu = 'dea_main_menu',
        options = options
    })
    
    lib.showContext('surveillance_menu')
end

-- Drone deployment
function OpenDroneMenu()
    local input = lib.inputDialog('Drone Surveillance', {
        { type = 'input', label = 'Target Player ID', description = 'Player server ID', required = true }
    })
    
    if input and input[1] then
        local targetID = tonumber(input[1])
        if targetID then
            TriggerServerEvent('dea-cartel:server:startDroneSurveillance', targetID)
        end
    end
end

-- GPS tracker menu
function OpenGPSMenu()
    local options = {
        {
            title = 'Approach Vehicle',
            description = 'Get within 2m and select vehicle to track',
            disabled = true
        }
    }
    
    lib.registerContext({
        id = 'gps_menu',
        title = 'GPS Tracker',
        menu = 'surveillance_menu',
        options = options
    })
    
    lib.showContext('gps_menu')
    
    -- Monitor nearby vehicles
    CreateThread(function()
        while lib.getContext() == 'gps_menu' do
            Wait(500)
            
            local playerCoords = GetEntityCoords(PlayerPedId())
            local nearbyVehicles = {}
            
            for _, vehicle in ipairs(GetGamePool('CVehicle')) do
                local vehicleCoords = GetEntityCoords(vehicle)
                local distance = #(playerCoords - vehicleCoords)
                
                if distance < 10 then
                    table.insert(nearbyVehicles, {
                        entity = vehicle,
                        netID = VehToNet(vehicle),
                        distance = distance
                    })
                end
            end
            
            if #nearbyVehicles > 0 then
                for _, vehicleData in ipairs(nearbyVehicles) do
                    DrawText3D(GetEntityCoords(vehicleData.entity) + vector3(0, 0, 1), 
                        'Plant GPS: Press [E]', 0.5)
                    
                    if GetDistanceBetweenCoords(playerCoords, GetEntityCoords(vehicleData.entity)) < 2.5 then
                        if IsControlJustReleased(0, 38) then  -- E key
                            TriggerServerEvent('dea-cartel:server:plantGPSTracker', vehicleData.netID)
                            lib.showContext()
                            break
                        end
                    end
                end
            end
        end
    end)
end

-- Drug test menu
function OpenDrugTestMenu()
    local options = {}
    
    for drugType, _ in pairs(Config.ProductionTypes) do
        table.insert(options, {
            title = 'Test for ' .. Config.ProductionTypes[drugType].label,
            description = 'Collect sample and test',
            icon = Config.ProductionTypes[drugType].icon,
            onSelect = function()
                TriggerServerEvent('dea-cartel:server:testDrug', drugType)
            end
        })
    end
    
    lib.registerContext({
        id = 'drug_test_menu',
        title = 'Drug Testing',
        menu = 'surveillance_menu',
        options = options
    })
    
    lib.showContext('drug_test_menu')
end

-- Wiretap menu
function OpenWiretapMenu()
    lib.notify({
        title = 'Wiretap',
        description = 'Approach suspect location and select to install',
        type = 'info',
        duration = 5000
    })
end

-- Raid menu
function OpenRaidMenu()
    local input = lib.inputDialog('Initiate Raid', {
        { type = 'input', label = 'Target Player ID', description = 'Player server ID', required = true },
        { type = 'input', label = 'Location', description = 'Property address or coords', required = true }
    })
    
    if input and input[1] and input[2] then
        local targetID = tonumber(input[1])
        if targetID then
            lib.progressBar({
                duration = 15000,
                label = 'Raid in progress...',
                useWhileDead = false,
                canCancel = false,
                disable = {
                    car = false,
                    move = false,
                    combat = false
                }
            })
            
            -- Use player position as raid location
            local coords = GetEntityCoords(PlayerPedId())
            TriggerServerEvent('dea-cartel:server:initiateRaid', targetID, coords, {})
            
            lib.alertDialog({
                header = 'Raid Initiated',
                content = 'Raid on Player ' .. targetID .. ' in progress.\n\nNote: suspect may evade, defend, or use distractions.',
                centered = true,
                cancel = false
            })
        end
    end
end

-- Arrest menu
function OpenArrestMenu()
    local options = {}
    
    for chargeType, chargeData in pairs(Config.Arrests.charges) do
        table.insert(options, {
            title = chargeType:upper(),
            description = 'Bail: ' .. Utils.formatMoney(chargeData.bail) .. ' | Jail: ' .. chargeData.jail / 60000 .. ' min',
            onSelect = function()
                local input = lib.inputDialog('Arrest Player', {
                    { type = 'input', label = 'Target Player ID', description = 'Player server ID', required = true }
                })
                
                if input and input[1] then
                    local targetID = tonumber(input[1])
                    if targetID then
                        lib.progressBar({
                            duration = 5000,
                            label = 'Processing arrest...',
                            useWhileDead = false,
                            canCancel = false,
                            disable = {
                                car = true,
                                move = true,
                                combat = true
                            }
                        })
                        
                        TriggerServerEvent('dea-cartel:server:arrestPlayer', targetID, chargeType)
                        
                        lib.alertDialog({
                            header = 'Arrest Complete',
                            content = 'Player ' .. targetID .. ' arrested for ' .. chargeType .. '\nCharge: ' .. chargeType .. '\nBail: ' .. Utils.formatMoney(chargeData.bail),
                            centered = true,
                            cancel = false
                        })
                    end
                end
            end
        })
    end
    
    lib.registerContext({
        id = 'arrest_menu',
        title = 'Make Arrest',
        menu = 'dea_main_menu',
        options = options
    })
    
    lib.showContext('arrest_menu')
end

-- Heat level tracker
function OpenHeatTracker()
    local input = lib.inputDialog('Heat Level Tracker', {
        { type = 'input', label = 'Target Player ID', description = 'Player server ID to monitor', required = true }
    })
    
    if input and input[1] then
        local targetID = tonumber(input[1])
        if targetID then
            lib.notify({
                title = 'Monitoring',
                description = 'Player ' .. targetID .. ' heat tracked',
                type = 'info',
                duration = 3000
            })
            
            -- Show heat updates for this player
            CreateThread(function()
                while true do
                    Wait(5000)
                    lib.notify({
                        title = 'Heat Update',
                        description = 'Current heat: ' .. ClientHeatLevel .. '/100',
                        type = 'info',
                        duration = 2000
                    })
                end
            end)
        end
    end
end

-- Draw 3D text helper
function DrawText3D(coords, text, size)
    local onScreen, screenX, screenY = World3dToScreen2d(coords.x, coords.y, coords.z)
    if onScreen then
        SetTextScale(0.0, size)
        SetTextFont(4)
        SetTextProbes(true)
        SetColourOfNextTextComponent(255, 0, 0, 255)
        SetTextCentre(true)
        BeginTextCommandDisplayText('STRING')
        AddTextComponentString(text)
        EndTextCommandDisplayText(screenX, screenY)
    end
end



print('^2[DEA-Cartel] ^7DEA client tools loaded^0')
