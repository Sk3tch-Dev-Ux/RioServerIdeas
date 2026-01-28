local QBCore = exports['qb-core']:GetCoreObject()

-- Track all bribery agreements
BribedAgents = {}  -- { agentID = { targetPlayerID, duration, trustLevel } }

-- Track informants
ActiveInformants = {}  -- { informantID = { type, owner, trustLevel, betrayalInfo } }

-- Track active hideouts
ActiveHideouts = {}  -- { hideoutID = { occupants = {}, defenses = {}, detected = false } }

-- Track dynamic raid events
DynamicRaidEvents = {}  -- { raidID = { type, location, time, status } }

-- Initialize hideouts
for _, hideout in ipairs(Config.Hideouts) do
    ActiveHideouts[hideout.id] = {
        id = hideout.id,
        name = hideout.name,
        coords = hideout.coords,
        occupants = {},
        defenses = {},
        detected = false,
        securityLevel = 0
    }
end

-- Bribe a DEA agent
function BribeAgent(source, agentID, amount)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then
        return { success = false, message = 'Player not found' }
    end
    
    local agent = QBCore.Functions.GetPlayer(tonumber(agentID))
    if not agent then
        return { success = false, message = 'Agent not found' }
    end
    
    if agent.PlayerData.job.name ~= 'police' then
        return { success = false, message = 'Target is not DEA' }
    end
    
    -- Check player heat
    if not PlayerHeatLevels[source] or PlayerHeatLevels[source].heat < Config.Bribery.minimumHeat then
        return { success = false, message = 'You need at least ' .. Config.Bribery.minimumHeat .. ' heat to bribe' }
    end
    
    -- Calculate bribe cost
    local rankMultiplier = Config.Bribery.rankMultipliers[agent.PlayerData.job.grade + 1] or 1.0
    local baseCost = Config.Bribery.baseCost * rankMultiplier
    
    if player.PlayerData.money.cash < baseCost then
        return { success = false, message = 'Not enough cash. Need: ' .. Utils.formatMoney(baseCost) }
    end
    
    -- Attempt bribe (risk of betrayal)
    local betrayalRoll = math.random()
    
    if betrayalRoll < Config.Bribery.betrayalChance then
        -- BETRAYAL!
        player.Functions.RemoveMoney('cash', baseCost)
        agent.Functions.AddMoney('cash', baseCost)
        
        -- Report player to DEA
        AddPlayerHeat(source, Config.Bribery.betrayalPenalty, 'Bribery attempt detected')
        
        player.Functions.Notify('BETRAYED: Agent reported you to DEA!', 'error', 5000)
        agent.Functions.Notify('Bribery offer received and reported', 'success', 3000)
        
        return { success = false, message = 'Agent betrayed you!' }
    else
        -- Successful bribe
        player.Functions.RemoveMoney('cash', baseCost)
        agent.Functions.AddMoney('cash', baseCost)
        
        local bribeID = 'bribe_' .. source .. '_' .. os.time()
        BribedAgents[bribeID] = {
            player = source,
            agent = tonumber(agentID),
            amount = baseCost,
            startTime = os.time(),
            duration = Config.Bribery.duration,
            trustLevel = (BribedAgents[bribeID] and (BribedAgents[bribeID].trustLevel + Config.Bribery.trustBuilding) or 1.0)
        }
        
        -- Apply bribery effects
        AddPlayerHeat(source, -baseCost / 500, 'Agent working in your favor')  -- Reduce heat accumulation
        
        player.Functions.Notify('Agent bribed successfully! ' .. (Config.Bribery.duration / 60000) .. ' minutes of protection', 'success', 5000)
        agent.Functions.Notify('You are now on the take', 'info', 3000)
        
        -- Notify agent of protection
        TriggerClientEvent('dea-cartel:client:agentProtected', tonumber(agentID), Config.Bribery.duration)
        
        return { success = true, message = 'Bribe successful', duration = Config.Bribery.duration }
    end
end

-- Recruit an informant
function RecruitInformant(source, informantType)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then
        return { success = false, message = 'Player not found' }
    end
    
    if not Config.Informants.types[informantType] then
        return { success = false, message = 'Invalid informant type' }
    end
    
    -- Count existing informants
    local informantCount = 0
    for _, inf in pairs(ActiveInformants) do
        if inf.owner == source then
            informantCount = informantCount + 1
        end
    end
    
    if informantCount >= Config.Informants.maxPerPlayer then
        return { success = false, message = 'Max informants reached' }
    end
    
    local informantData = Config.Informants.types[informantType]
    
    if player.PlayerData.money.cash < informantData.cost then
        return { success = false, message = 'Not enough cash. Need: ' .. Utils.formatMoney(informantData.cost) }
    end
    
    -- Recruit informant
    player.Functions.RemoveMoney('cash', informantData.cost)
    
    local informantID = 'informant_' .. source .. '_' .. os.time()
    ActiveInformants[informantID] = {
        id = informantID,
        type = informantType,
        owner = source,
        ownerName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
        trustLevel = math.random() * 0.5 + 0.5,  -- 50-100% trust
        startTime = os.time(),
        intel = {}
    }
    
    player.Functions.Notify('Informant recruited! Type: ' .. informantData.label, 'success', 4000)
    
    -- Informant provides intel every 5 minutes
    CreateThread(function()
        while ActiveInformants[informantID] do
            Wait(300000)  -- 5 minutes
            
            if math.random() < Config.Informants.types[informantType].reliability then
                -- Intel received
                local intelType = next(informantData.intel)
                player.Functions.Notify('Informant: Intel received (' .. intelType .. ')', 'info', 3000)
            end
            
            -- Betrayal check
            if math.random() < Config.Informants.betrayalChance then
                BetrayInformant(informantID, source)
            end
        end
    end)
    
    return { success = true, informantID = informantID }
end

-- Informant betrays player
function BetrayInformant(informantID, playerID)
    local informant = ActiveInformants[informantID]
    if not informant then return end
    
    local player = QBCore.Functions.GetPlayer(playerID)
    if not player then return end
    
    -- DEA gets paid for information
    local reward = Config.Informants.betrayalReward
    
    -- Give informant protection
    local protectedInformants = {}
    for _, agentID in ipairs(GetPlayers()) do
        local agent = QBCore.Functions.GetPlayer(tonumber(agentID))
        if agent and agent.PlayerData.job.name == 'police' then
            -- Agent can't arrest this informant for protection duration
            protectedInformants[tonumber(agentID)] = os.time() + Config.Informants.informantProtection
        end
    end
    
    -- Add heat to player
    AddPlayerHeat(playerID, Config.Informants.betrayalChance * 100, 'Informant betrayed you')
    
    -- Remove informant
    ActiveInformants[informantID] = nil
    
    player.Functions.Notify('Your informant betrayed you to DEA!', 'error', 5000)
end

-- Enter a hideout
function EnterHideout(source, hideoutID)
    if not ActiveHideouts[hideoutID] then
        return { success = false, message = 'Hideout not found' }
    end
    
    local hideout = ActiveHideouts[hideoutID]
    local player = QBCore.Functions.GetPlayer(source)
    
    if not player then
        return { success = false, message = 'Player not found' }
    end
    
    if #hideout.occupants >= Config.Hideouts[hideoutID].capacity then
        return { success = false, message = 'Hideout is full' }
    end
    
    table.insert(hideout.occupants, source)
    
    player.Functions.Notify('Entered hideout: ' .. hideout.name, 'success', 3000)
    TriggerClientEvent('dea-cartel:client:enterHideout', source, hideoutID)
    
    return { success = true, message = 'Entered hideout' }
end

-- Exit hideout
function ExitHideout(source, hideoutID)
    if not ActiveHideouts[hideoutID] then
        return { success = false, message = 'Hideout not found' }
    end
    
    local hideout = ActiveHideouts[hideoutID]
    
    for i, occupant in ipairs(hideout.occupants) do
        if occupant == source then
            table.remove(hideout.occupants, i)
            break
        end
    end
    
    local player = QBCore.Functions.GetPlayer(source)
    if player then
        player.Functions.Notify('Left hideout', 'success', 2000)
    end
    
    return { success = true }
end

-- Install defense system in hideout
function InstallDefense(source, hideoutID, defenseName)
    if not ActiveHideouts[hideoutID] then
        return { success = false, message = 'Hideout not found' }
    end
    
    if not Config.DefenseSystems[defenseName] then
        return { success = false, message = 'Invalid defense system' }
    end
    
    local hideout = ActiveHideouts[hideoutID]
    local defense = Config.DefenseSystems[defenseName]
    
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return { success = false, message = 'Player not found' } end
    
    -- Check money
    if player.PlayerData.money.cash < defense.cost then
        return { success = false, message = 'Not enough cash. Need: ' .. Utils.formatMoney(defense.cost) }
    end
    
    -- Check if already installed
    if hideout.defenses[defenseName] then
        return { success = false, message = 'Defense already installed' }
    end
    
    -- Install defense
    player.Functions.RemoveMoney('cash', defense.cost)
    hideout.defenses[defenseName] = {
        installed = os.time(),
        active = true
    }
    
    hideout.securityLevel = hideout.securityLevel + 1
    
    player.Functions.Notify(defense.name .. ' installed! Security Level: ' .. hideout.securityLevel, 'success', 4000)
    
    return { success = true, message = 'Defense installed' }
end

-- Trigger random DEA raid event
function TriggerRandomRaidEvent()
    -- Get high-heat players
    local raidTargets = {}
    for playerID, heatData in pairs(PlayerHeatLevels) do
        if heatData.heat >= Config.DEARaidEvents.minHeatForRandom then
            table.insert(raidTargets, tonumber(playerID))
        end
    end
    
    if #raidTargets == 0 then return end
    
    -- Pick random target
    local targetID = raidTargets[math.random(#raidTargets)]
    local target = QBCore.Functions.GetPlayer(targetID)
    
    if not target then return end
    
    -- Select raid type based on weight
    local raidType = SelectRandomRaidType()
    
    local raidID = 'dynamic_raid_' .. os.time()
    local location = GetEntityCoords(GetPlayerPed(GetPlayerFromServerId(targetID)))
    
    DynamicRaidEvents[raidID] = {
        id = raidID,
        type = raidType,
        targetPlayer = targetID,
        targetName = target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname,
        location = location,
        startTime = os.time(),
        status = 'executing',
        agentCount = Config.DEARaidEvents.raidTypes[raidType].agents
    }
    
    -- Notify target of incoming raid
    target.Functions.Notify('RAID INCOMING: ' .. raidType .. ' raid detected!', 'error', 7000)
    TriggerClientEvent('dea-cartel:client:raidWarning', targetID, raidType)
    
    -- Notify all DEA
    for _, agentID in ipairs(GetPlayers()) do
        local agent = QBCore.Functions.GetPlayer(tonumber(agentID))
        if agent and agent.PlayerData.job.name == 'police' then
            agent.Functions.Notify('RAID: ' .. raidType .. ' raid on ' .. target.PlayerData.charinfo.firstname, 'info', 5000)
        end
    end
end

-- Select random raid type based on weight
function SelectRandomRaidType()
    local totalWeight = 0
    for _, raidType in pairs(Config.DEARaidEvents.raidTypes) do
        totalWeight = totalWeight + (raidType.weight or 1)
    end
    
    local roll = math.random() * totalWeight
    local currentWeight = 0
    
    for raidName, raidType in pairs(Config.DEARaidEvents.raidTypes) do
        currentWeight = currentWeight + (raidType.weight or 1)
        if roll <= currentWeight then
            return raidName
        end
    end
    
    return 'standard'
end

-- Evade active raid
function EvadeRaid(source, hideoutID)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return { success = false, message = 'Player not found' } end
    
    -- Cost to evade
    if player.PlayerData.money.cash < Config.EvasionMechanics.evadeCost then
        return { success = false, message = 'Not enough cash to evade. Need: ' .. Utils.formatMoney(Config.EvasionMechanics.evadeCost) }
    end
    
    -- Roll for success
    local evadeSuccess = math.random() < Config.EvasionMechanics.evasionSuccessRate
    
    if evadeSuccess then
        player.Functions.RemoveMoney('cash', Config.EvasionMechanics.evadeCost)
        
        -- Reduce heat significantly
        AddPlayerHeat(source, -25, 'Successfully evaded raid')
        
        player.Functions.Notify('Raid evaded! Heat reduced.', 'success', 5000)
        
        -- Grant reputation bonus
        local rep = GetPlayerReputation(source)
        SetPlayerReputation(source, rep + Config.RaidOutcomes.cartelRewards.evadedRaid.respect)
        
        return { success = true, message = 'Raid evaded' }
    else
        -- Failed evasion
        player.Functions.RemoveMoney('cash', Config.EvasionMechanics.evadeCost)
        AddPlayerHeat(source, Config.EvasionMechanics.failurePenalty, 'Failed raid evasion')
        
        player.Functions.Notify('Evasion failed! Heat increased.', 'error', 5000)
        
        return { success = false, message = 'Evasion failed' }
    end
end

-- Get player reputation
function GetPlayerReputation(source)
    if not PlayerHeatLevels[source] then
        return 0
    end
    return PlayerHeatLevels[source].reputation or 0
end

-- Set player reputation
function SetPlayerReputation(source, amount)
    if not PlayerHeatLevels[source] then
        PlayerHeatLevels[source] = {}
    end
    
    PlayerHeatLevels[source].reputation = math.max(Config.Reputation.minReputation, math.min(Config.Reputation.maxReputation, amount))
    
    local player = QBCore.Functions.GetPlayer(source)
    if player then
        player.Functions.Notify('Reputation: ' .. PlayerHeatLevels[source].reputation, 'info', 2000)
    end
end

-- Tick for random raid events
CreateThread(function()
    while true do
        Wait(Config.DEARaidEvents.checkInterval)
        
        if Config.DEARaidEvents.enabled then
            if math.random() < Config.DEARaidEvents.randomRaidChance then
                TriggerRandomRaidEvent()
            end
        end
        
        -- Expire bribed agents
        for bribeID, bribeData in pairs(BribedAgents) do
            local elapsed = (os.time() - bribeData.startTime) * 1000
            if elapsed > bribeData.duration then
                BribedAgents[bribeID] = nil
            end
        end
    end
end)

-- Network events
RegisterNetEvent('dea-cartel:server:bribeAgent', function(agentID)
    local result = BribeAgent(source, agentID, 0)
    TriggerClientEvent('dea-cartel:client:operationResult', source, result)
end)

RegisterNetEvent('dea-cartel:server:recruitInformant', function(informantType)
    local result = RecruitInformant(source, informantType)
    TriggerClientEvent('dea-cartel:client:operationResult', source, result)
end)

RegisterNetEvent('dea-cartel:server:enterHideout', function(hideoutID)
    local result = EnterHideout(source, hideoutID)
    TriggerClientEvent('dea-cartel:client:operationResult', source, result)
end)

RegisterNetEvent('dea-cartel:server:exitHideout', function(hideoutID)
    local result = ExitHideout(source, hideoutID)
    TriggerClientEvent('dea-cartel:client:operationResult', source, result)
end)

RegisterNetEvent('dea-cartel:server:installDefense', function(hideoutID, defenseName)
    local result = InstallDefense(source, hideoutID, defenseName)
    TriggerClientEvent('dea-cartel:client:operationResult', source, result)
end)

RegisterNetEvent('dea-cartel:server:evadeRaid', function(hideoutID)
    local result = EvadeRaid(source, hideoutID)
    TriggerClientEvent('dea-cartel:client:operationResult', source, result)
end)

print('^2[DEA-Cartel] ^7Dealer vs DEA dynamics initialized^0')
