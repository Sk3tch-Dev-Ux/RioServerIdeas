local QBCore = exports['qb-core']:GetCoreObject()
local lib = exports.ox_lib

-- ========== DASHBOARD STATE ==========

DashboardState = {
    growOps = {},
    deaIntel = {
        heatLevel = 0,
        raidProbability = 0,
        lastRaidTime = 0,
        raidHistory = {}
    },
    territories = {},
    auctions = {}
}

-- ========== GROW OPS DASHBOARD ==========

function ShowGrowOpsDashboard()
    if not Config.Dashboards.growOpsUI.enabled then
        return lib.notify({ title = 'Unavailable', description = 'Dashboard not available', type = 'error' })
    end
    
    local options = {
        {
            title = 'Active Grow Operations',
            description = 'Monitor your grow houses and labs',
            disabled = true
        },
        {
            title = '---',
            disabled = true
        }
    }
    
    -- Get player operations (would be synced from server)
    -- For now, show placeholder
    table.insert(options, {
        title = 'No active operations',
        icon = 'fas fa-leaf',
        description = 'Start a new grow house or lab',
        disabled = true
    })
    
    table.insert(options, {
        title = '---',
        disabled = true
    })
    
    table.insert(options, {
        title = 'Alerts & Status',
        disabled = true
    })
    
    if Config.Dashboards.growOpsUI.alerts.plantReady then
        table.insert(options, {
            title = 'Plant Ready for Harvest',
            icon = 'fas fa-check',
            description = 'Check your operations',
            onSelect = function()
                lib.notify({ title = 'Check your grow house', type = 'info', duration = 3000 })
            end
        })
    end
    
    lib.registerContext({
        id = 'growops_dashboard',
        title = 'Grow Operations Dashboard',
        menu = 'criminal_main_menu',
        options = options
    })
    
    lib.showContext('growops_dashboard')
end

-- ========== DEA INTEL DASHBOARD ==========

function ShowDEAIntelDashboard()
    if not Config.Dashboards.deaUI.enabled then
        return lib.notify({ title = 'Unavailable', description = 'DEA intel not available', type = 'error' })
    end
    
    local options = {
        {
            title = 'DEA Heat Level',
            description = 'Current heat: ' .. math.floor(DashboardState.deaIntel.heatLevel),
            icon = 'fas fa-temperature-high',
            disabled = true
        },
        {
            title = 'Raid Probability',
            description = math.floor(DashboardState.deaIntel.raidProbability * 100) .. '%',
            icon = 'fas fa-bomb',
            disabled = true
        },
        {
            title = '---',
            disabled = true
        },
        {
            title = 'Heat Reduction Strategies',
            disabled = true
        }
    }
    
    -- Heat reduction options
    table.insert(options, {
        title = 'Lay Low (costs money)',
        description = 'Pay NPCs to reduce heat',
        icon = 'fas fa-handshake',
        onSelect = function()
            lib.notify({ title = 'Not yet implemented', type = 'info' })
        end
    })
    
    table.insert(options, {
        title = 'Safe House Hideout',
        description = 'Hide in safe house to lose DEA',
        icon = 'fas fa-house',
        onSelect = function()
            lib.notify({ title = 'Navigate to safe house', type = 'info' })
        end
    })
    
    table.insert(options, {
        title = '---',
        disabled = true
    })
    
    table.insert(options, {
        title = 'Recent Raids',
        disabled = true
    })
    
    if #DashboardState.deaIntel.raidHistory > 0 then
        for i, raid in ipairs(DashboardState.deaIntel.raidHistory) do
            if i <= 3 then  -- Show last 3 raids
                table.insert(options, {
                    title = 'Raid #' .. i,
                    description = 'Time: ' .. raid.time .. ', Items: ' .. raid.itemsSeized,
                    icon = 'fas fa-shield-alt',
                    disabled = true
                })
            end
        end
    else
        table.insert(options, {
            title = 'No raid history',
            description = 'Stay safe and keep it that way!',
            disabled = true
        })
    end
    
    lib.registerContext({
        id = 'dea_intel_dashboard',
        title = 'DEA Intel Dashboard',
        menu = 'criminal_main_menu',
        options = options
    })
    
    lib.showContext('dea_intel_dashboard')
end

-- ========== TERRITORY DASHBOARD ==========

function ShowTerritoryDashboard()
    if not Config.Dashboards.territoryUI.enabled then
        return lib.notify({ title = 'Unavailable', description = 'Territory system not available', type = 'error' })
    end
    
    local options = {
        {
            title = 'Territory Control Map',
            description = 'View and manage gang territories',
            disabled = true
        },
        {
            title = '---',
            disabled = true
        }
    }
    
    if #DashboardState.territories > 0 then
        for _, territory in ipairs(DashboardState.territories) do
            local ownerText = territory.owner and 'Controlled' or 'Unclaimed'
            local statusColor = territory.owner and '~g~' or '~y~'
            
            table.insert(options, {
                title = territory.name,
                description = statusColor .. ownerText .. '~s~',
                icon = 'fas fa-map-marker-alt',
                onSelect = function()
                    ShowTerritoryDetails(territory)
                end
            })
        end
    else
        table.insert(options, {
            title = 'No territories available',
            description = 'Territories not loaded',
            disabled = true
        })
    end
    
    lib.registerContext({
        id = 'territory_dashboard',
        title = 'Territory Control',
        menu = 'criminal_main_menu',
        options = options
    })
    
    lib.showContext('territory_dashboard')
end

function ShowTerritoryDetails(territory)
    local options = {
        {
            title = territory.name,
            description = territory.owner and 'Controlled by gang' or 'Unclaimed',
            disabled = true
        },
        {
            title = '---',
            disabled = true
        }
    }
    
    if Config.Dashboards.territoryUI.showBonuses and territory.bonuses then
        table.insert(options, {
            title = 'Territory Bonuses',
            disabled = true
        })
        
        for bonusType, bonusValue in pairs(territory.bonuses) do
            if bonusValue > 0 then
                table.insert(options, {
                    title = bonusType:gsub('_', ' '):upper(),
                    description = '+' .. (bonusValue * 100) .. '%',
                    icon = 'fas fa-star',
                    disabled = true
                })
            end
        end
    end
    
    if not territory.owner then
        table.insert(options, {
            title = '---',
            disabled = true
        })
        
        table.insert(options, {
            title = 'Claim Territory',
            description = 'Cost: $' .. territory.claimCost,
            icon = 'fas fa-flag',
            onSelect = function()
                TriggerServerEvent('dea-cartel:server:claimTerritory', territory.id)
            end
        })
    else
        table.insert(options, {
            title = '---',
            disabled = true
        })
        
        if territory.isVulnerable then
            table.insert(options, {
                title = 'Challenge Territory',
                description = 'Initiate turf war',
                icon = 'fas fa-fist-raised',
                onSelect = function()
                    TriggerServerEvent('dea-cartel:server:challengeTerritory', territory.id)
                end
            })
        else
            table.insert(options, {
                title = 'Territory Vulnerable In: ' .. territory.timeUntilVulnerable .. 's',
                description = 'Wait for control period to end',
                disabled = true
            })
        end
    end
    
    lib.registerContext({
        id = 'territory_details_' .. territory.id,
        title = territory.name,
        menu = 'territory_dashboard',
        options = options
    })
    
    lib.showContext('territory_details_' .. territory.id)
end

-- ========== AUCTION DASHBOARD ==========

function ShowAuctionDashboard()
    if not Config.Dashboards.auctionUI.enabled then
        return lib.notify({ title = 'Unavailable', description = 'Auction house not available', type = 'error' })
    end
    
    local options = {
        {
            title = 'Black Market Auctions',
            description = 'Bid on rare items and equipment',
            disabled = true
        },
        {
            title = '---',
            disabled = true
        },
        {
            title = 'View Active Auctions',
            icon = 'fas fa-gavel',
            onSelect = function()
                ShowActiveAuctions()
            end
        },
        {
            title = 'My Auction Items',
            icon = 'fas fa-box',
            onSelect = function()
                ShowMyAuctionItems()
            end
        },
        {
            title = 'Auction Statistics',
            icon = 'fas fa-chart-line',
            onSelect = function()
                ShowAuctionStats()
            end
        }
    }
    
    lib.registerContext({
        id = 'auction_dashboard',
        title = 'Black Market Auctions',
        menu = 'criminal_main_menu',
        options = options
    })
    
    lib.showContext('auction_dashboard')
end

function ShowActiveAuctions()
    TriggerServerEvent('dea-cartel:server:getAuctions')
    
    -- Show loading
    lib.notify({ title = 'Loading auctions...', type = 'info' })
end

function ShowMyAuctionItems()
    TriggerServerEvent('dea-cartel:server:getMyAuctions')
    
    -- Show loading
    lib.notify({ title = 'Loading your items...', type = 'info' })
end

function ShowAuctionStats()
    TriggerServerEvent('dea-cartel:server:getAuctionStats')
end

-- ========== NETWORK EVENT HANDLERS ==========

RegisterNetEvent('dea-cartel:client:auctionListReceived', function(auctions)
    local options = {
        {
            title = 'Active Auctions',
            description = #auctions .. ' items available',
            disabled = true
        },
        {
            title = '---',
            disabled = true
        }
    }
    
    if #auctions > 0 then
        for _, auction in ipairs(auctions) do
            table.insert(options, {
                title = auction.item.name,
                description = 'Current bid: $' .. auction.currentBid .. ' | ' .. math.ceil(auction.timeRemaining) .. 's left',
                icon = auction.item.icon,
                onSelect = function()
                    ShowAuctionDetails(auction)
                end
            })
        end
    else
        table.insert(options, {
            title = 'No active auctions',
            description = 'Check back soon',
            disabled = true
        })
    end
    
    lib.registerContext({
        id = 'active_auctions_list',
        title = 'Active Auctions',
        menu = 'auction_dashboard',
        options = options
    })
    
    lib.showContext('active_auctions_list')
end

function ShowAuctionDetails(auction)
    local input = lib.inputDialog('Place Bid', {
        {
            type = 'number',
            label = 'Bid Amount',
            description = 'Minimum: $' .. auction.minNextBid,
            required = true
        }
    })
    
    if input then
        local bidAmount = tonumber(input[1])
        if bidAmount then
            TriggerServerEvent('dea-cartel:server:placeBid', auction.id, bidAmount)
        end
    end
end

RegisterNetEvent('dea-cartel:client:myAuctionsReceived', function(items)
    local options = {
        {
            title = 'My Auction Items',
            disabled = true
        },
        {
            title = '---',
            disabled = true
        }
    }
    
    if #items.won > 0 then
        table.insert(options, {
            title = 'Items Won: ' .. #items.won,
            disabled = true
        })
        
        for _, item in ipairs(items.won) do
            table.insert(options, {
                title = item.item.name,
                description = 'Won for $' .. item.price,
                icon = item.item.icon,
                onSelect = function()
                    TriggerServerEvent('dea-cartel:server:useAuctionItem', item.item.id)
                end
            })
        end
    else
        table.insert(options, {
            title = 'No items won yet',
            description = 'Win auctions to get items',
            disabled = true
        })
    end
    
    lib.registerContext({
        id = 'my_auctions_list',
        title = 'My Items',
        menu = 'auction_dashboard',
        options = options
    })
    
    lib.showContext('my_auctions_list')
end

RegisterNetEvent('dea-cartel:client:auctionStatsReceived', function(stats)
    lib.notify({
        title = 'Auction Statistics',
        description = 'Active: ' .. stats.activeAuctions .. ' | Total Value: $' .. stats.totalValue .. ' | Average Bid: $' .. stats.averageBid,
        type = 'info',
        duration = 4000
    })
end)

RegisterNetEvent('dea-cartel:client:territoriesReceived', function(territories)
    DashboardState.territories = territories
end)

RegisterNetEvent('dea-cartel:client:territoriesUpdated', function(territories)
    DashboardState.territories = territories
    
    lib.notify({
        title = 'Territory Update',
        description = 'Territory control map updated',
        type = 'info',
        duration = 2000
    })
end)

RegisterNetEvent('dea-cartel:client:territoryClaimedNotification', function(data)
    lib.notify({
        title = 'Territory Claimed!',
        description = data.claimant .. ' claimed ' .. data.territory,
        type = 'warning',
        duration = 4000
    })
end)

RegisterNetEvent('dea-cartel:client:territoryConqueredNotification', function(data)
    lib.notify({
        title = 'Territory Conquered!',
        description = data.victor .. ' conquered ' .. data.territory,
        type = 'error',
        duration = 5000
    })
end)

RegisterNetEvent('dea-cartel:client:territoryVulnerable', function(territoryID)
    lib.notify({
        title = 'Territory Vulnerable',
        description = 'A territory is now open to challenge',
        type = 'warning',
        duration = 3000
    })
end)

RegisterNetEvent('dea-cartel:client:auctionCreated', function(auctionID, auction)
    lib.notify({
        title = 'New Auction',
        description = auction.item.name .. ' starting at $' .. auction.startPrice,
        type = 'info',
        duration = 3000
    })
end)

RegisterNetEvent('dea-cartel:client:bidPlaced', function(auctionID, bidData)
    lib.notify({
        title = 'Bid Placed',
        description = bidData.bidder .. ' bid $' .. bidData.amount .. ' with ' .. math.ceil(bidData.timeRemaining) .. 's left',
        type = 'info',
        duration = 2000
    })
end)

RegisterNetEvent('dea-cartel:client:auctionWon', function(item)
    lib.notify({
        title = 'Auction Won!',
        description = 'You won the ' .. item.name .. ' auction!',
        type = 'success',
        duration = 4000
    })
end)

-- ========== REQUEST DATA ON SPAWN ==========

CreateThread(function()
    Wait(2000)
    TriggerServerEvent('dea-cartel:server:getTerritories')
    TriggerServerEvent('dea-cartel:server:getAuctions')
end)

print('^2[DEA-Cartel] ^7Dashboard system client loaded^0')
