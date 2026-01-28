local QBCore = exports['qb-core']:GetCoreObject()
local lib = exports.ox_lib

-- Track current hideout
CurrentHideout = nil
HideoutBlips = {}

-- Raid warning tracking
ActiveRaidWarning = nil

-- Agent protection tracking
ProtectedByAgent = false

-- Handle agent protection
RegisterNetEvent('dea-cartel:client:agentProtected', function(duration)
    ProtectedByAgent = true
    
    lib.notify({
        title = 'Protected',
        description = 'Agent working in your favor for ' .. duration / 60000 .. ' minutes',
        type = 'success',
        duration = 5000
    })
    
    -- Remove protection after duration
    SetTimeout(duration, function()
        ProtectedByAgent = false
        lib.notify({
            title = 'Protection Expired',
            description = 'Agent is no longer on the take',
            type = 'warning',
            duration = 3000
        })
    end)
end)

-- Raid warning
RegisterNetEvent('dea-cartel:client:raidWarning', function(raidType)
    ActiveRaidWarning = {
        type = raidType,
        startTime = os.time(),
        active = true
    }
    
    TriggerScreenEffect("RaceTurbo", 3000)
    PlaySoundFrontend(-1, "CONFIRM_BEEP", "HUD_MINI_GAME_SOUNDSET", true)
    
    lib.notify({
        title = 'RAID WARNING',
        description = raidType .. ' raid incoming! Take cover or evade!',
        type = 'error',
        duration = 7000
    })
end)

-- Handle entering hideout
RegisterNetEvent('dea-cartel:client:enterHideout', function(hideoutID)
    CurrentHideout = hideoutID
    
    lib.notify({
        title = 'Safe',
        description = 'You are in the hideout. Heat generation reduced.',
        type = 'success',
        duration = 3000
    })
end)

-- Spawn hideout zones
CreateThread(function()
    Wait(1000)
    
    for _, hideout in ipairs(Config.Hideouts) do
        local zoneID = exports.ox_target:addSphereZone({
            coords = hideout.coords,
            radius = 5.0,
            debug = false,
            options = {
                {
                    name = 'hideout_enter_' .. hideout.id,
                    label = 'Enter ' .. hideout.name,
                    icon = hideout.icon,
                    distance = 5.0,
                    onSelect = function()
                        ShowHideoutMenu(hideout)
                    end
                }
            }
        })
        
        HideoutBlips[hideout.id] = zoneID
    end
end)

-- Hideout menu
function ShowHideoutMenu(hideout)
    local options = {
        {
            title = hideout.name,
            description = 'Safe house',
            disabled = true
        },
        {
            title = 'Enter Hideout',
            description = 'Take shelter and reduce heat',
            icon = hideout.icon,
            onSelect = function()
                TriggerServerEvent('dea-cartel:server:enterHideout', hideout.id)
                CurrentHideout = hideout.id
            end
        }
    }
    
    if CurrentHideout == hideout.id then
        table.insert(options, {
            title = 'Exit Hideout',
            description = 'Leave the hideout',
            icon = 'fas fa-door-open',
            onSelect = function()
                TriggerServerEvent('dea-cartel:server:exitHideout', hideout.id)
                CurrentHideout = nil
            end
        })
        
        table.insert(options, {
            title = 'Install Defenses',
            description = 'Alarm, jammer, safe, etc',
            icon = 'fas fa-shield',
            arrow = true,
            onSelect = function()
                ShowDefenseMenu(hideout.id)
            end
        })
    end
    
    table.insert(options, {
        title = 'Hideout Info',
        description = 'Capacity: ' .. #Config.Hideouts[hideout.id] .. ' | Security: Medium',
        disabled = true
    })
    
    lib.registerContext({
        id = 'hideout_menu_' .. hideout.id,
        title = hideout.name,
        options = options
    })
    
    lib.showContext('hideout_menu_' .. hideout.id)
end

-- Defense installation menu
function ShowDefenseMenu(hideoutID)
    local options = {}
    
    for defenseName, defenseData in pairs(Config.DefenseSystems) do
        table.insert(options, {
            title = defenseData.name,
            description = defenseData.description .. '\nCost: ' .. Utils.formatMoney(defenseData.cost),
            icon = defenseData.icon,
            onSelect = function()
                lib.alertDialog({
                    header = 'Install Defense',
                    content = defenseData.name .. '\n\nCost: ' .. Utils.formatMoney(defenseData.cost),
                    centered = true,
                    cancel = true,
                    onConfirm = function()
                        lib.progressBar({
                            duration = 12000,
                            label = 'Installing defense system...',
                            useWhileDead = false,
                            canCancel = true,
                            disable = {
                                car = true,
                                move = true,
                                combat = true
                            }
                        })
                        
                        TriggerServerEvent('dea-cartel:server:installDefense', hideoutID, defenseName)
                        
                        lib.notify({
                            title = 'Defense Installed',
                            description = defenseData.name .. ' installed successfully',
                            type = 'success',
                            duration = 3000
                        })
                    end
                })
            end
        })
    end
    
    lib.registerContext({
        id = 'defense_menu_' .. hideoutID,
        title = 'Install Defenses',
        menu = 'hideout_menu_' .. hideoutID,
        options = options
    })
    
    lib.showContext('defense_menu_' .. hideoutID)
end

-- Bribery menu for nearby DEA agents
function ShowBriberyMenu()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local nearbyAgents = {}
    
    for _, playerID in ipairs(GetPlayers()) do
        local agent = tonumber(playerID)
        if agent then
            local agentPed = GetPlayerPed(agent)
            if agentPed and DoesEntityExist(agentPed) then
                local agentCoords = GetEntityCoords(agentPed)
                local distance = #(playerCoords - agentCoords)
                
                if distance < 50 then
                    table.insert(nearbyAgents, {
                        id = agent,
                        name = GetPlayerName(agent),
                        distance = math.floor(distance)
                    })
                end
            end
        end
    end
    
    if #nearbyAgents == 0 then
        lib.notify({
            title = 'No Agents Nearby',
            description = 'No DEA agents within 50m',
            type = 'info',
            duration = 3000
        })
        return
    end
    
    local options = {
        {
            title = 'Bribe DEA Agent',
            description = 'Pay agent to look the other way',
            disabled = true
        }
    }
    
    for _, agent in ipairs(nearbyAgents) do
        table.insert(options, {
            title = agent.name,
            description = agent.distance .. 'm away | Risk: Betrayal possible',
             onSelect = function()
                 lib.alertDialog({
                     header = 'Bribe ' .. agent.name,
                     content = 'Risk: Agent may betray you and report to DEA\n\nContinue?',
                     centered = true,
                     cancel = true,
                     onConfirm = function()
                         lib.progressBar({
                            duration = 3000,
                            label = 'Making offer...',
                            useWhileDead = false,
                            canCancel = false,
                            disable = {
                                car = true,
                                move = true,
                                combat = true
                            }
                        })
                        
                        TriggerServerEvent('dea-cartel:server:bribeAgent', agent.id)
                        
                        lib.notify({
                            title = 'Offer Made',
                            description = 'Agent may accept or report you to DEA',
                            type = 'warning',
                            duration = 5000
                        })
                     end
                 })
            end
        })
    end
    
    lib.registerContext({
        id = 'bribery_menu',
        title = 'Bribe Agent',
        options = options
    })
    
    lib.showContext('bribery_menu')
end

-- Informant recruitment menu
function ShowInformantMenu()
    local options = {
        {
            title = 'Recruit Informant',
            description = 'Get inside information on DEA activities',
            disabled = true
        }
    }
    
    for informantType, informantData in pairs(Config.Informants.types) do
        table.insert(options, {
            title = 'Recruit: ' .. informantData.label,
            description = 'Cost: ' .. Utils.formatMoney(informantData.cost) .. ' | Loyalty: ' .. string.format('%.0f%%', informantData.reliability * 100),
            icon = 'fas fa-user-secret',
             onSelect = function()
                 lib.alertDialog({
                     header = 'Recruit Informant',
                     content = informantData.label .. '\n\nCost: ' .. Utils.formatMoney(informantData.cost) .. '\nRisk: May betray you',
                     centered = true,
                     cancel = true,
                     onConfirm = function()
                         lib.progressBar({
                            duration = 5000,
                            label = 'Recruiting informant...',
                            useWhileDead = false,
                            canCancel = true,
                            disable = {
                                car = true,
                                move = true,
                                combat = true
                            }
                        })
                        
                        TriggerServerEvent('dea-cartel:server:recruitInformant', informantType)
                        
                        lib.notify({
                            title = 'Informant Recruited',
                            description = informantData.label .. ' is now your informant',
                            type = 'success',
                            duration = 4000
                        })
                     end
                 })
            end
        })
    end
    
    lib.registerContext({
        id = 'informant_menu',
        title = 'Recruit Informant',
        options = options
    })
    
    lib.showContext('informant_menu')
end

-- Raid evasion menu
function ShowRaidEvadeMenu()
    if not ActiveRaidWarning or not ActiveRaidWarning.active then
        lib.notify({
            title = 'No Raid',
            description = 'There is no active raid',
            type = 'info',
            duration = 2000
        })
        return
    end
    
    local options = {
        {
            title = 'Active Raid: ' .. ActiveRaidWarning.type,
            description = 'Incoming raid detected!',
            disabled = true
        },
         {
             title = 'Evade Raid',
             description = 'Pay off local cops to let you escape (70% success)',
             icon = 'fas fa-person-running',
             onSelect = function()
                 lib.progressBar({
                    duration = 8000,
                    label = 'Attempting to evade...',
                    useWhileDead = false,
                    canCancel = false,
                    disable = {
                        car = false,
                        move = false,
                        combat = true
                    }
                })
                
                TriggerServerEvent('dea-cartel:server:evadeRaid', CurrentHideout)
                ActiveRaidWarning.active = false
                
                lib.notify({
                    title = 'Evasion Attempt',
                    description = 'Attempting to evade the incoming raid...',
                    type = 'warning',
                    duration = 5000
                })
             end
         },
        {
            title = 'Use Distraction',
            description = 'Deploy smoke bomb or cash',
            icon = 'fas fa-explosion',
            arrow = true,
            onSelect = function()
                ShowDistractionMenu()
            end
        },
        {
            title = 'Defend Hideout',
            description = 'Stand and fight (high risk)',
            icon = 'fas fa-gun',
            onSelect = function()
                lib.notify({
                    title = 'Raid Defense',
                    description = 'Prepare your weapons and fortify position',
                    type = 'warning',
                    duration = 5000
                })
            end
        }
    }
    
    lib.registerContext({
        id = 'raid_evade_menu',
        title = 'Raid Response',
        options = options
    })
    
    lib.showContext('raid_evade_menu')
end

-- Distraction options
function ShowDistractionMenu()
    local options = {}
    
     for _, distraction in ipairs(Config.EvasionMechanics.distractions) do
         table.insert(options, {
             title = distraction.name,
             description = 'Cost: ' .. Utils.formatMoney(distraction.cost) .. ' | Duration: ' .. distraction.duration / 1000 .. 's',
             onSelect = function()
                 lib.progressBar({
                    duration = 2000,
                    label = 'Deploying ' .. distraction.name .. '...',
                    useWhileDead = false,
                    canCancel = false,
                    disable = {
                        car = false,
                        move = true,
                        combat = true
                    }
                })
                
                TriggerServerEvent('dea-cartel:server:useDistraction', distraction.name)
                
                lib.notify({
                    title = 'Distraction Active',
                    description = distraction.name .. ' deployed!',
                    type = 'warning',
                    duration = distraction.duration / 1000 + 1000
                })
             end
         })
     end
    
    lib.registerContext({
        id = 'distraction_menu',
        title = 'Distraction Tactics',
        menu = 'raid_evade_menu',
        options = options
    })
    
    lib.showContext('distraction_menu')
end

-- Main dealer menu (criminal options)
function OpenDealerMenu()
    local options = {
        {
            title = 'Criminal Operations',
            description = 'Survive and thrive against DEA',
            disabled = true
        },
        {
            title = 'Bribe DEA Agent',
            description = 'Pay agent to look the other way',
            icon = 'fas fa-money-bill',
            onSelect = function()
                ShowBriberyMenu()
            end
        },
        {
            title = 'Recruit Informant',
            description = 'Get inside DEA information',
            icon = 'fas fa-user-secret',
            onSelect = function()
                ShowInformantMenu()
            end
        },
        {
            title = 'Find Safe House',
            description = 'Locate hideouts in area',
            icon = 'fas fa-map-location-dot',
            onSelect = function()
                ShowHideoutLocations()
            end
        },
        {
            title = 'Raid Response',
            description = 'Evade or defend active raids',
            icon = 'fas fa-shield-halved',
            onSelect = function()
                ShowRaidEvadeMenu()
            end
        }
    }
    
    lib.registerContext({
        id = 'dealer_menu',
        title = 'Criminal Operations',
        options = options
    })
    
    lib.showContext('dealer_menu')
end

-- Show nearby hideout locations
function ShowHideoutLocations()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local options = {}
    
    for _, hideout in ipairs(Config.Hideouts) do
        local distance = math.floor(#(playerCoords - hideout.coords))
        table.insert(options, {
            title = hideout.name,
            description = distance .. 'm away | Capacity: ' .. Config.Hideouts[hideout.id].capacity,
            icon = hideout.icon,
            onSelect = function()
                SetNewWaypoint(hideout.coords.x, hideout.coords.y)
                lib.notify({
                    title = 'GPS Set',
                    description = 'Heading to ' .. hideout.name,
                    type = 'success',
                    duration = 3000
                })
            end
        })
    end
    
    lib.registerContext({
        id = 'hideout_locations',
        title = 'Safe Houses',
        options = options
    })
    
    lib.showContext('hideout_locations')
end



-- Monitor hideout heat reduction
CreateThread(function()
    while true do
        Wait(30000)  -- Check every 30 seconds
        
        if CurrentHideout then
            local hideout = nil
            for _, h in ipairs(Config.Hideouts) do
                if h.id == CurrentHideout then
                    hideout = h
                    break
                end
            end
            
            if hideout then
                -- Reduce incoming heat while in hideout
                TriggerEvent('dea-cartel:client:hideoutProtection', hideout.heatReduction)
            end
        end
    end
end)

print('^2[DEA-Cartel] ^7Dealer vs DEA dynamics client loaded^0')
