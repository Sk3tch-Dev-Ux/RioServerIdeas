local QBCore = exports['qb-core']:GetCoreObject()

-- ========== AUCTION HOUSE SYSTEM ==========

-- Track active auctions
ActiveAuctions = {}  -- { auctionID = { item, startPrice, currentBid, bidder, bidderName, endTime } }
AuctionCounter = 0

-- Track player auction data
PlayerAuctions = {}  -- { playerID = { won = {}, selling = {}, balance = 0 } }

-- Initialize auction system
CreateThread(function()
    while true do
        Wait(Config.BlackMarketAuctions.refreshInterval)
        GenerateNewAuctions()
        CheckAuctionExpiry()
    end
end)

-- ========== AUCTION GENERATION ==========

function GenerateNewAuctions()
    if not Config.BlackMarketAuctions.enabled then return end
    
    -- Limit concurrent auctions
    if #ActiveAuctions >= Config.BlackMarketAuctions.maxAuctionsActive then
        return
    end
    
    -- Random chance to spawn new auction
    local randomItem = math.random(1, 100)
    local auctionItem = nil
    
    if randomItem <= 50 then
        -- Rare seeds (50% chance)
        auctionItem = Config.BlackMarketAuctions.rareSeeds[math.random(1, #Config.BlackMarketAuctions.rareSeeds)]
    else
        -- Rare equipment (50% chance)
        auctionItem = Config.BlackMarketAuctions.rareEquipment[math.random(1, #Config.BlackMarketAuctions.rareEquipment)]
    end
    
    if not auctionItem then return end
    
    -- Create new auction
    AuctionCounter = AuctionCounter + 1
    local auctionID = 'auction_' .. AuctionCounter
    
    local startingPrice = math.floor(auctionItem.baseValue * Config.BlackMarketAuctions.startingPriceMultiplier)
    
    ActiveAuctions[auctionID] = {
        id = auctionID,
        item = auctionItem,
        startPrice = startingPrice,
        currentBid = startingPrice,
        currentBidder = nil,
        currentBidderName = 'No bids',
        endTime = os.time() + (Config.BlackMarketAuctions.auctionDuration / 1000),
        createdAt = os.time()
    }
    
    -- Notify all players
    TriggerClientEvent('dea-cartel:client:auctionCreated', -1, auctionID, ActiveAuctions[auctionID])
    
    print('^2[Auctions] ^7New auction created: ' .. auctionItem.name .. ' - Starting bid: $' .. startingPrice .. '^0')
end

-- ========== BIDDING SYSTEM ==========

RegisterNetEvent('dea-cartel:server:placeBid', function(auctionID, bidAmount)
    local source = source
    local player = QBCore.Functions.GetPlayer(source)
    
    if not player then return end
    
    -- Validate auction exists
    local auction = ActiveAuctions[auctionID]
    if not auction then
        return TriggerClientEvent('QBCore:Notify', source, 'Auction not found', 'error')
    end
    
    -- Check if auction expired
    if os.time() > auction.endTime then
        return TriggerClientEvent('QBCore:Notify', source, 'Auction has ended', 'error')
    end
    
    -- Validate bid amount
    if bidAmount < (auction.currentBid + Config.BlackMarketAuctions.minBidIncrement) then
        return TriggerClientEvent('QBCore:Notify', source, 'Bid must be at least $' .. (auction.currentBid + Config.BlackMarketAuctions.minBidIncrement), 'error')
    end
    
    -- Check player has sufficient funds
    if player.PlayerData.money.bank < bidAmount then
        return TriggerClientEvent('QBCore:Notify', source, 'Insufficient funds', 'error')
    end
    
    -- Refund previous bidder if exists
    if auction.currentBidder then
        local previousBidder = QBCore.Functions.GetPlayer(auction.currentBidder)
        if previousBidder then
            previousBidder.Functions.AddMoney('bank', auction.currentBid)
            previousBidder.Functions.Notify('You were outbid on ' .. auction.item.name, 'info')
        end
    end
    
    -- Place new bid
    auction.currentBid = bidAmount
    auction.currentBidder = source
    auction.currentBidderName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
    
    -- Notify all players of new bid
    TriggerClientEvent('dea-cartel:client:bidPlaced', -1, auctionID, {
        bidder = auction.currentBidderName,
        amount = bidAmount,
        timeRemaining = (auction.endTime - os.time())
    })
    
    player.Functions.Notify('Bid placed on ' .. auction.item.name .. ' for $' .. bidAmount, 'success')
end)

-- ========== AUCTION COMPLETION ==========

function CheckAuctionExpiry()
    local currentTime = os.time()
    local expiredAuctions = {}
    
    for auctionID, auction in pairs(ActiveAuctions) do
        if currentTime > auction.endTime then
            table.insert(expiredAuctions, auctionID)
            
            -- Award to winner if exists
            if auction.currentBidder then
                local winner = QBCore.Functions.GetPlayer(auction.currentBidder)
                if winner then
                    -- Charge winning bid
                    winner.Functions.RemoveMoney('bank', auction.currentBid)
                    
                    -- Give item to winner
                    local itemData = {
                        item = auction.item,
                        acquiredAt = os.time(),
                        price = auction.currentBid
                    }
                    
                    -- Store auction data for winner
                    if not PlayerAuctions[auction.currentBidder] then
                        PlayerAuctions[auction.currentBidder] = { won = {}, selling = {} }
                    end
                    
                    table.insert(PlayerAuctions[auction.currentBidder].won, itemData)
                    
                    -- Notify winner
                    winner.Functions.Notify('You won the auction for ' .. auction.item.name .. ' for $' .. auction.currentBid, 'success')
                    TriggerClientEvent('dea-cartel:client:auctionWon', auction.currentBidder, auction.item)
                    
                    -- Add reputation for big purchases
                    if auction.currentBid > 50000 then
                        AddReputation(auction.currentBidder, 10, 'Rare item auction purchase')
                    end
                end
            else
                -- No bids - auction expires
                TriggerClientEvent('dea-cartel:client:auctionExpired', -1, auctionID, auction.item.name)
            end
        end
    end
    
    -- Remove expired auctions
    for _, auctionID in ipairs(expiredAuctions) do
        ActiveAuctions[auctionID] = nil
    end
end

-- ========== GET ACTIVE AUCTIONS ==========

RegisterNetEvent('dea-cartel:server:getAuctions', function()
    local source = source
    local auctionList = {}
    
    for auctionID, auction in pairs(ActiveAuctions) do
        table.insert(auctionList, {
            id = auctionID,
            item = auction.item,
            startPrice = auction.startPrice,
            currentBid = auction.currentBid,
            currentBidder = auction.currentBidderName,
            timeRemaining = math.max(0, auction.endTime - os.time()),
            minNextBid = auction.currentBid + Config.BlackMarketAuctions.minBidIncrement
        })
    end
    
    TriggerClientEvent('dea-cartel:client:auctionListReceived', source, auctionList)
end)

-- ========== PLAYER AUCTION INVENTORY ==========

function GetPlayerAuctionItems(source)
    if not PlayerAuctions[source] then
        PlayerAuctions[source] = { won = {}, selling = {} }
    end
    
    return PlayerAuctions[source]
end

RegisterNetEvent('dea-cartel:server:getMyAuctions', function()
    local source = source
    local items = GetPlayerAuctionItems(source)
    
    TriggerClientEvent('dea-cartel:client:myAuctionsReceived', source, items)
end)

-- ========== USE AUCTION ITEM ==========

RegisterNetEvent('dea-cartel:server:useAuctionItem', function(itemID)
    local source = source
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return end
    
    local items = GetPlayerAuctionItems(source)
    
    -- Find item
    local itemFound = false
    for i, item in ipairs(items.won) do
        if item.item.id == itemID then
            itemFound = true
            
            -- Apply item effects based on type
            if item.item.yield_multiplier then
                -- Seed bonus - add to player data
                if not player.PlayerData.metadata.auction_seeds then
                    player.PlayerData.metadata.auction_seeds = {}
                end
                
                table.insert(player.PlayerData.metadata.auction_seeds, {
                    id = itemID,
                    yield_multiplier = item.item.yield_multiplier,
                    growTime_multiplier = item.item.growTime_multiplier,
                    detection_reduction = item.item.detection_reduction
                })
                
                player.Functions.Notify('Added ' .. item.item.name .. ' to grow house', 'success')
            elseif item.item.yield_bonus then
                -- Equipment bonus - add upgrade
                if not player.PlayerData.metadata.auction_equipment then
                    player.PlayerData.metadata.auction_equipment = {}
                end
                
                table.insert(player.PlayerData.metadata.auction_equipment, {
                    id = itemID,
                    yield_bonus = item.item.yield_bonus,
                    detection_reduction = item.item.detection_reduction,
                    heat_reduction = item.item.heat_reduction
                })
                
                player.Functions.Notify('Equipped ' .. item.item.name, 'success')
            end
            
            -- Remove from inventory
            table.remove(items.won, i)
            
            -- Add reputation
            AddReputation(source, 5, 'Used rare auction item')
            
            break
        end
    end
    
    if not itemFound then
        TriggerClientEvent('QBCore:Notify', source, 'Item not found', 'error')
    end
end)

-- ========== AUCTION STATISTICS ==========

function GetAuctionStats()
    local stats = {
        activeAuctions = #ActiveAuctions,
        totalValue = 0,
        totalBids = 0,
        averageBid = 0
    }
    
    for _, auction in pairs(ActiveAuctions) do
        stats.totalValue = stats.totalValue + auction.currentBid
        if auction.currentBidder then
            stats.totalBids = stats.totalBids + 1
        end
    end
    
    if stats.totalBids > 0 then
        stats.averageBid = math.floor(stats.totalValue / stats.totalBids)
    end
    
    return stats
end

RegisterNetEvent('dea-cartel:server:getAuctionStats', function()
    local source = source
    local stats = GetAuctionStats()
    TriggerClientEvent('dea-cartel:client:auctionStatsReceived', source, stats)
end)

print('^2[DEA-Cartel] ^7Auction house system initialized^0')
