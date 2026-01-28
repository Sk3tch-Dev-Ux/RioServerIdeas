local QBCore = exports['qb-core']:GetCoreObject()

-- ========== TERRITORY CONTROL SYSTEM ==========

-- Track territory ownership
TerritoryControl = {}  -- { territoryID = { owner = playerID, gang = gangID, controlledAt = time, isVulnerable = bool } }

-- Track territory challenges
TerritoryChallenge = {}  -- { territoryID = { attacker = playerID, defender = playerID, active = bool, startTime = time } }

-- Initialize territories (all neutral at start)
for _, territory in ipairs(Config.GangTerritories.territories) do
    TerritoryControl[territory.id] = {
        id = territory.id,
        name = territory.name,
        owner = nil,
        gang = nil,
        controlledAt = 0,
        isVulnerable = false,
        claimants = {},
        lastActivity = os.time()
    }
end

-- ========== TERRITORY CLAIMING ==========

RegisterNetEvent('dea-cartel:server:claimTerritory', function(territoryID)
    local source = source
    local player = QBCore.Functions.GetPlayer(source)
    
    if not player then return end
    
    local territory = TerritoryControl[territoryID]
    if not territory then
        return TriggerClientEvent('QBCore:Notify', source, 'Territory not found', 'error')
    end
    
    -- Check if territory already claimed
    if territory.owner and not territory.isVulnerable then
        return TriggerClientEvent('QBCore:Notify', source, 'Territory already controlled', 'error')
    end
    
    -- Find territory config for cost
    local territoryConfig = nil
    for _, t in ipairs(Config.GangTerritories.territories) do
        if t.id == territoryID then
            territoryConfig = t
            break
        end
    end
    
    if not territoryConfig then return end
    
    -- Check funds
    if player.PlayerData.money.bank < territoryConfig.claimCost then
        return TriggerClientEvent('QBCore:Notify', source, 'Insufficient funds ($' .. territoryConfig.claimCost .. ' needed)', 'error')
    end
    
    -- Charge claiming fee
    player.Functions.RemoveMoney('bank', territoryConfig.claimCost)
    
    -- Claim territory
    territory.owner = source
    territory.gang = player.PlayerData.metadata.gang or 'independent'
    territory.controlledAt = os.time()
    territory.isVulnerable = false
    
    -- Notify all players
    TriggerClientEvent('dea-cartel:client:territoryClaimedNotification', -1, {
        territory = territory.name,
        claimant = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
        gang = territory.gang
    })
    
    player.Functions.Notify('You claimed ' .. territory.name .. '!', 'success')
    AddReputation(source, 50, 'Claimed territory')
    
    -- Sync to clients
    SyncTerritoriesToClients()
end)

-- ========== TERRITORY CHALLENGE (TURF WAR) ==========

RegisterNetEvent('dea-cartel:server:challengeTerritory', function(territoryID)
    local source = source
    local player = QBCore.Functions.GetPlayer(source)
    
    if not player then return end
    
    local territory = TerritoryControl[territoryID]
    if not territory then
        return TriggerClientEvent('QBCore:Notify', source, 'Territory not found', 'error')
    end
    
    -- Can only challenge vulnerable territories
    if not territory.isVulnerable then
        return TriggerClientEvent('QBCore:Notify', source, 'Territory is not under challenge', 'error')
    end
    
    -- Can't challenge own territory
    if territory.owner == source then
        return TriggerClientEvent('QBCore:Notify', source, 'Cannot challenge your own territory', 'error')
    end
    
    -- Check if challenge already active
    if TerritoryChallenge[territoryID] and TerritoryChallenge[territoryID].active then
        return TriggerClientEvent('QBCore:Notify', source, 'Challenge already in progress', 'error')
    end
    
    -- Create challenge
    TerritoryChallenge[territoryID] = {
        id = territoryID,
        attacker = source,
        defender = territory.owner,
        active = true,
        startTime = os.time(),
        attackersPresent = { source },
        defendersPresent = { territory.owner }
    }
    
    -- Notify defender
    local defender = QBCore.Functions.GetPlayer(territory.owner)
    if defender then
        defender.Functions.Notify('Your territory ' .. territory.name .. ' is under attack!', 'error')
    end
    
    player.Functions.Notify('Challenge initiated for ' .. territory.name .. '! Defenders have ' .. (Config.GangTerritories.turfWar.preparationTime / 1000) .. ' seconds to defend!', 'warning')
    
    -- Start defense countdown
    StartTurfWarCountdown(territoryID)
end)

-- ========== TURF WAR COUNTDOWN & RESOLUTION ==========

function StartTurfWarCountdown(territoryID)
    SetTimeout(Config.GangTerritories.turfWar.preparationTime, function()
        ResolveTurfWar(territoryID)
    end)
end

function ResolveTurfWar(territoryID)
    local territory = TerritoryControl[territoryID]
    local challenge = TerritoryChallenge[territoryID]
    
    if not territory or not challenge or not challenge.active then return end
    
    -- Check if participants are online
    local attacker = QBCore.Functions.GetPlayer(challenge.attacker)
    local defender = QBCore.Functions.GetPlayer(challenge.defender)
    
    if not attacker or not defender then
        -- One side disappeared - other side wins
        local winner = attacker or defender
        if winner then
            if not attacker then
                AwardTerritoryToWinner(territoryID, challenge.attacker)
            else
                AwardTerritoryToWinner(territoryID, challenge.attacker)
            end
        end
        challenge.active = false
        return
    end
    
    -- Count participants
    local attackersCount = 0
    local defendersCount = 0
    
    for _, pid in ipairs(challenge.attackersPresent) do
        if QBCore.Functions.GetPlayer(pid) then
            attackersCount = attackersCount + 1
        end
    end
    
    for _, pid in ipairs(challenge.defendersPresent) do
        if QBCore.Functions.GetPlayer(pid) then
            defendersCount = defendersCount + 1
        end
    end
    
    -- Minimum participants required
    if attackersCount < Config.GangTerritories.turfWar.challengerAdvantage.agentsRequired then
        TriggerClientEvent('QBCore:Notify', challenge.attacker, 'Challenge failed - insufficient attackers', 'error')
        challenge.active = false
        return
    end
    
    if defendersCount < Config.GangTerritories.turfWar.challengerAdvantage.defendersRequired then
        -- Defenders didn't show up - attackers win
        AwardTerritoryToWinner(territoryID, challenge.attacker)
        challenge.active = false
        return
    end
    
    -- Random outcome based on numbers
    local successChance = math.min(0.9, attackersCount / (attackersCount + defendersCount))
    local attackersWin = math.random() < successChance
    
    if attackersWin then
        AwardTerritoryToWinner(territoryID, challenge.attacker)
    else
        -- Defenders win, keep territory
        for _, pid in ipairs(challenge.defendersPresent) do
            local defender = QBCore.Functions.GetPlayer(pid)
            if defender then
                defender.Functions.AddMoney('bank', Config.GangTerritories.turfWar.challengerAdvantage.defenseSuccessPayout)
                defender.Functions.Notify('Territory defense successful!', 'success')
                AddReputation(pid, 75, 'Defended territory')
            end
        end
    end
    
    challenge.active = false
end

function AwardTerritoryToWinner(territoryID, winnerID)
    local territory = TerritoryControl[territoryID]
    local winner = QBCore.Functions.GetPlayer(winnerID)
    
    if not winner then return end
    
    -- Transfer ownership
    territory.owner = winnerID
    territory.gang = winner.PlayerData.metadata.gang or 'independent'
    territory.controlledAt = os.time()
    territory.isVulnerable = false
    
    -- Award winner
    winner.Functions.AddMoney('bank', Config.GangTerritories.turfWar.challengerAdvantage.challengeSuccessPayout)
    winner.Functions.Notify('Territory conquered: ' .. territory.name, 'success')
    
    local bonuses = GetTerritoryBonuses(territoryID)
    if bonuses then
        -- Apply bonuses to winner
        winner.PlayerData.metadata.territory_bonuses = bonuses
        winner.Functions.Notify('Territory bonuses activated!', 'success')
    end
    
    AddReputation(winnerID, 150, 'Conquered territory')
    
    -- Notify all players
    TriggerClientEvent('dea-cartel:client:territoryConqueredNotification', -1, {
        territory = territory.name,
        victor = winner.PlayerData.charinfo.firstname .. ' ' .. winner.PlayerData.charinfo.lastname,
        gang = territory.gang
    })
    
    -- Make vulnerable in 1 hour
    SetTimeout(Config.GangTerritories.territories[territoryID].defenseDuration, function()
        territory.isVulnerable = true
        TriggerClientEvent('dea-cartel:client:territoryVulnerable', -1, territoryID)
    end)
    
    SyncTerritoriesToClients()
end

-- ========== TERRITORY BONUSES ==========

function GetTerritoryBonuses(territoryID)
    for _, territory in ipairs(Config.GangTerritories.territories) do
        if territory.id == territoryID then
            return territory.bonuses
        end
    end
    return nil
end

function ApplyTerritoryBonus(source, bonusType)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return 1.0 end
    
    if not player.PlayerData.metadata.territory_bonuses then
        return 1.0
    end
    
    local bonuses = player.PlayerData.metadata.territory_bonuses
    
    if bonusType == 'dealer_payout' then
        return 1.0 + (bonuses.dealer_payout_boost or 0)
    elseif bonusType == 'bulk_sale' then
        return 1.0 + (bonuses.bulk_sale_bonus or 0)
    elseif bonusType == 'production_speed' then
        return bonuses.production_speed or 1.0
    elseif bonusType == 'yield' then
        return 1.0 + (bonuses.yield_bonus or 0)
    elseif bonusType == 'detection_reduction' then
        return bonuses.detection_reduction or 0
    elseif bonusType == 'heat_reduction' then
        return bonuses.heat_reduction or 0
    end
    
    return 1.0
end

-- ========== PLAYER TERRITORY BONUSES ==========

RegisterNetEvent('dea-cartel:server:getTerritoryBonuses', function()
    local source = source
    local player = QBCore.Functions.GetPlayer(source)
    
    if not player then return end
    
    local bonuses = player.PlayerData.metadata.territory_bonuses or {}
    TriggerClientEvent('dea-cartel:client:bonusesReceived', source, bonuses)
end)

-- ========== TERRITORY INFO ==========

RegisterNetEvent('dea-cartel:server:getTerritories', function()
    local source = source
    local territories = {}
    
    for _, territory in ipairs(Config.GangTerritories.territories) do
        local control = TerritoryControl[territory.id]
        local isVulnerable = control.isVulnerable
        local timeUntilVulnerable = 0
        
        if control.controlledAt > 0 and not isVulnerable then
            timeUntilVulnerable = math.max(0, (control.controlledAt + (territory.defenseDuration / 1000)) - os.time())
        end
        
        table.insert(territories, {
            id = territory.id,
            name = territory.name,
            coords = territory.coords,
            radius = territory.radius,
            blipSprite = territory.blipSprite,
            blipColor = territory.blipColor,
            owner = control.owner,
            gang = control.gang,
            isVulnerable = isVulnerable,
            timeUntilVulnerable = timeUntilVulnerable,
            bonuses = territory.bonuses,
            claimCost = territory.claimCost
        })
    end
    
    TriggerClientEvent('dea-cartel:client:territoriesReceived', source, territories)
end)

-- ========== SYNC TO CLIENTS ==========

function SyncTerritoriesToClients()
    TriggerClientEvent('dea-cartel:client:territoriesUpdated', -1, TerritoryControl)
end

-- Initial sync on resource start
CreateThread(function()
    Wait(1000)
    SyncTerritoriesToClients()
end)

-- Periodic vulnerability checks (every 5 minutes)
CreateThread(function()
    while true do
        Wait(300000)
        
        for territoryID, control in pairs(TerritoryControl) do
            if control.owner and not control.isVulnerable then
                -- Check if defense duration expired
                local config = nil
                for _, t in ipairs(Config.GangTerritories.territories) do
                    if t.id == territoryID then
                        config = t
                        break
                    end
                end
                
                if config then
                    local timeElapsed = (os.time() - control.controlledAt) * 1000
                    if timeElapsed > config.defenseDuration then
                        control.isVulnerable = true
                        TriggerClientEvent('dea-cartel:client:territoryVulnerable', -1, territoryID)
                    end
                end
            end
        end
    end
end)

print('^2[DEA-Cartel] ^7Territory control system initialized^0')
