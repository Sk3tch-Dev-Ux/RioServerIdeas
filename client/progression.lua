local QBCore = exports['qb-core']:GetCoreObject()
local lib = exports.ox_lib

-- Client-side progression tracking
ClientProgression = {
    reputation = 0,
    tier = 'street_soldier',
    tierData = {},
    perks = {},
    limits = {}
}

ClientMarketDemand = {
    marijuana = 1.0,
    cocaine = 1.0,
    methamphetamine = 1.0
}

-- ========== PROGRESSION DISPLAY ==========

function DisplayProgressionUI()
    local player = QBCore.GetPlayerData()
    
    -- Build tier progress bar
    local tierData = ClientProgression.tierData
    local rep = ClientProgression.reputation
    
    local nextTier = nil
    local progress = 0
    
    if tierData.maxReputation == 150 then
        -- Street Soldier -> Lieutenant
        nextTier = 'Lieutenant'
        progress = math.floor((rep / 150) * 100)
    elseif tierData.maxReputation == 400 then
        -- Lieutenant -> Boss
        nextTier = 'Boss'
        progress = math.floor(((rep - 150) / 250) * 100)
    elseif tierData.maxReputation == 750 then
        -- Boss -> Kingpin
        nextTier = 'Kingpin'
        progress = math.floor(((rep - 400) / 350) * 100)
    else
        -- Kingpin (maxed out)
        nextTier = 'MAXED'
        progress = 100
    end
    
    -- Display UI elements
    lib.notify({
        title = 'Progression',
        description = tierData.label .. ' - Reputation ' .. math.floor(rep),
        type = 'info',
        duration = 4000
    })
end

function ShowProgressionMenu()
    local player = QBCore.GetPlayerData()
    
    local options = {
        {
            title = 'Progression Status',
            description = ClientProgression.tierData.label .. ' (Reputation: ' .. ClientProgression.reputation .. ')',
            disabled = true
        },
        {
            title = '---',
            disabled = true
        }
    }
    
    -- Show current tier info
    table.insert(options, {
        title = 'Current Tier: ' .. ClientProgression.tierData.label,
        description = ClientProgression.tierData.description,
        icon = ClientProgression.tierData.icon,
        disabled = true
    })
    
    -- Show perks
    if #ClientProgression.perks > 0 then
        table.insert(options, {
            title = '---',
            disabled = true
        })
        
        table.insert(options, {
            title = 'Tier Perks',
            disabled = true
        })
        
        for _, perk in ipairs(ClientProgression.perks) do
            table.insert(options, {
                title = perk,
                icon = 'fas fa-star',
                disabled = true
            })
        end
    end
    
    -- Show tier limits
    table.insert(options, {
        title = '---',
        disabled = true
    })
    
    table.insert(options, {
        title = 'Tier Limits',
        disabled = true
    })
    
    table.insert(options, {
        title = 'Max Operations',
        description = ClientProgression.limits.maxOperations .. ' active operations',
        disabled = true
    })
    
    table.insert(options, {
        title = 'Max Plants per Grow House',
        description = ClientProgression.limits.maxPlants .. ' plants',
        disabled = true
    })
    
    table.insert(options, {
        title = 'Max Bribes',
        description = ClientProgression.limits.maxBribes .. ' active bribes',
        disabled = true
    })
    
    table.insert(options, {
        title = 'Max Informants',
        description = ClientProgression.limits.maxInformants .. ' active informants',
        disabled = true
    })
    
    if ClientProgression.limits.maxLaundering > 0 then
        table.insert(options, {
            title = 'Max Laundering',
            description = 'Up to $' .. ClientProgression.limits.maxLaundering .. ' per transaction',
            disabled = true
        })
    else
        table.insert(options, {
            title = 'Money Laundering',
            description = 'Unlocked at Lieutenant rank',
            disabled = true
        })
    end
    
    table.insert(options, {
        title = 'Max Bulk Sale',
        description = ClientProgression.limits.maxBulkSale .. 'g per sale',
        disabled = true
    })
    
    lib.registerContext({
        id = 'progression_menu',
        title = 'Progression & Perks',
        menu = 'criminal_main_menu',
        options = options
    })
    
    lib.showContext('progression_menu')
end

-- ========== REPUTATION NOTIFICATIONS ==========

RegisterNetEvent('dea-cartel:client:updateReputation', function(reputation, tier)
    ClientProgression.reputation = reputation
    ClientProgression.tier = tier
    
    -- Notification with tier name
    local tierNames = {
        street_soldier = 'Street Soldier',
        lieutenant = 'Lieutenant',
        boss = 'Boss',
        kingpin = 'Kingpin'
    }
    
    lib.notify({
        title = 'Reputation Updated',
        description = tierNames[tier] .. ' - Rep: ' .. math.floor(reputation),
        type = 'info',
        duration = 3000
    })
end)

-- ========== TIER UNLOCK NOTIFICATION ==========

RegisterNetEvent('dea-cartel:client:tierUnlock', function(tierName, tierData)
    ClientProgression.tier = tierName
    ClientProgression.tierData = tierData
    
    -- Big celebration notification
    lib.notify({
        title = 'TIER UP!',
        description = 'You are now ' .. tierData.label,
        type = 'success',
        duration = 5000
    })
    
    -- Play celebratory sound (if available)
    -- TriggerEvent('InteractSound_CL:PlayOnOne', 'CONFIRM_BEEP', 0.6)
    
    -- Show tier perks menu
    Wait(1000)
    ShowTierUnlockDetails(tierData)
end)

function ShowTierUnlockDetails(tierData)
    local options = {
        {
            title = 'NEW TIER UNLOCKED',
            description = tierData.label,
            disabled = true
        },
        {
            title = '---',
            disabled = true
        },
        {
            title = tierData.description,
            icon = tierData.icon,
            disabled = true
        },
        {
            title = '---',
            disabled = true
        },
        {
            title = 'New Perks:',
            disabled = true
        }
    }
    
    -- Show perks
    if tierData.perks then
        for _, perk in ipairs(tierData.perks) do
            table.insert(options, {
                title = perk,
                icon = 'fas fa-star',
                disabled = true
            })
        end
    end
    
    -- Show new limits
    table.insert(options, {
        title = '---',
        disabled = true
    })
    
    table.insert(options, {
        title = 'New Tier Limits:',
        disabled = true
    })
    
    table.insert(options, {
        title = 'Max Operations: ' .. tierData.maxOperations,
        icon = 'fas fa-building',
        disabled = true
    })
    
    table.insert(options, {
        title = 'Max Plants: ' .. tierData.maxPlants,
        icon = 'fas fa-leaf',
        disabled = true
    })
    
    table.insert(options, {
        title = 'Dealer Payout: ' .. string.format('%.0f%%', tierData.dealerPayoutMultiplier * 100),
        icon = 'fas fa-percent',
        disabled = true
    })
    
    lib.registerContext({
        id = 'tier_unlock_menu',
        title = tierData.label,
        options = options
    })
    
    lib.showContext('tier_unlock_menu')
end

-- ========== PROGRESSION DATA SYNC ==========

RegisterNetEvent('dea-cartel:client:updateProgression', function(data)
    ClientProgression = data
end)

-- Request progression on spawn
CreateThread(function()
    Wait(2000)
    TriggerServerEvent('dea-cartel:server:requestProgression')
end)

-- ========== COOLDOWN WARNINGS ==========

RegisterNetEvent('dea-cartel:client:cooldownWarning', function(actionType, remainingSeconds)
    lib.notify({
        title = 'Cooldown Active',
        description = actionType .. ': ' .. math.ceil(remainingSeconds) .. 's remaining',
        type = 'warning',
        duration = 2000
    })
end)

-- ========== ECONOMY FEEDBACK ==========

RegisterNetEvent('dea-cartel:client:diminishingReturnsWarning', function(activity, returnPercentage)
    lib.notify({
        title = 'Grind Protection',
        description = activity .. ' returns at ' .. string.format('%.0f%%', returnPercentage * 100),
        type = 'warning',
        duration = 2000
    })
end)

RegisterNetEvent('dea-cartel:client:earningsCapWarning', function(remaining)
    lib.notify({
        title = 'Daily Earnings Cap',
        description = 'Remaining: ' .. Utils.formatMoney(remaining),
        type = 'warning',
        duration = 3000
    })
end)

-- ========== MARKET DEMAND DISPLAY ==========

RegisterNetEvent('dea-cartel:client:updateMarketDemand', function(demand)
    ClientMarketDemand = demand
    
    -- Optionally show demand changes
    local changes = {}
    
    if math.abs(demand.marijuana - 1.0) > 0.1 then
        local change = (demand.marijuana - 1.0) * 100
        table.insert(changes, 'Marijuana: ' .. string.format('%+.0f%%', change))
    end
    
    if math.abs(demand.cocaine - 1.0) > 0.1 then
        local change = (demand.cocaine - 1.0) * 100
        table.insert(changes, 'Cocaine: ' .. string.format('%+.0f%%', change))
    end
    
    if math.abs(demand.methamphetamine - 1.0) > 0.1 then
        local change = (demand.methamphetamine - 1.0) * 100
        table.insert(changes, 'Meth: ' .. string.format('%+.0f%%', change))
    end
    
    if #changes > 0 then
        lib.notify({
            title = 'Market Demand Shift',
            description = table.concat(changes, ', '),
            type = 'info',
            duration = 3000
        })
    end
end)

-- ========== ADD TO MAIN MENU ==========

-- Register context for progression in criminal menu
function AddProgressionMenuOption()
    -- This gets called from interactions.lua to add progression to main menu
    if not lib.getContext('criminal_main_menu') then
        return
    end
    
    -- Add progression option to criminal menu if needed
end

-- ========== HELPER FUNCTIONS ==========

function GetClientTier()
    return ClientProgression.tier or 'street_soldier'
end

function GetClientReputation()
    return ClientProgression.reputation or 0
end

function CanAccessFeature(feature)
    if feature == 'laundering' then
        return ClientProgression.limits.maxLaundering > 0
    elseif feature == 'bulk_sales' then
        return true
    end
    
    return true
end

function GetTierLimit(limitType)
    return ClientProgression.limits[limitType] or 0
end

function GetMarketMultiplier(drugType)
    return ClientMarketDemand[drugType] or 1.0
end

print('^2[DEA-Cartel] ^7Progression system client loaded^0')
