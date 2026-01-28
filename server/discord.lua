-- ========== DISCORD INTEGRATION ==========

local webhooks = Config.Discord.webhooks
local colors = Config.Discord.colors
local logging = Config.Discord.logging

-- ========== WEBHOOK HELPER ==========

function SendDiscordEmbed(webhook, title, description, color, fields)
    if not Config.Discord.enabled or not webhook or webhook == '' then
        return
    end
    
    -- Validate webhook format
    if not string.match(webhook, 'discordapp.com/api/webhooks') then
        print('^1[Discord] ^7Invalid webhook URL^0')
        return
    end
    
    local payload = {
        embeds = {
            {
                title = title,
                description = description,
                color = color,
                timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
                fields = fields or {},
                footer = {
                    text = Config.ServerInfo.name .. ' v' .. Config.ServerInfo.version
                }
            }
        }
    }
    
    PerformHttpRequest(webhook, function(err, text, headers)
        if err ~= 200 then
            print('^1[Discord] ^7Webhook error: ' .. tostring(err) .. '^0')
        end
    end, 'POST', json.encode(payload), {
        ['Content-Type'] = 'application/json'
    })
end

-- ========== RAID ALERTS ==========

function LogRaidToDiscord(raidData)
    if not logging.majorRaids or not webhooks.raids then return end
    
    local title = 'DEA RAID IN PROGRESS'
    local description = 'Operation detected and raided by DEA agents'
    
    local fields = {
        {
            name = 'Location',
            value = raidData.location or 'Unknown',
            inline = true
        },
        {
            name = 'Operation Type',
            value = raidData.type or 'Unknown',
            inline = true
        },
        {
            name = 'Heat Level',
            value = tostring(math.floor(raidData.heat or 0)),
            inline = true
        },
        {
            name = 'Agents Dispatched',
            value = tostring(raidData.agentCount or 0),
            inline = true
        }
    }
    
    if raidData.owner then
        table.insert(fields, {
            name = 'Owner',
            value = raidData.owner,
            inline = true
        })
    end
    
    SendDiscordEmbed(webhooks.raids, title, description, colors.raid, fields)
end

-- ========== TERRITORY CONQUEST ALERTS ==========

function LogTerritoryConquestToDiscord(conquestData)
    if not logging.territoryConquests or not webhooks.territoryWars then return end
    
    local title = 'TERRITORY CONQUERED'
    local description = conquestData.victor .. ' conquered ' .. conquestData.territory
    
    local fields = {
        {
            name = 'Territory',
            value = conquestData.territory,
            inline = true
        },
        {
            name = 'Victor',
            value = conquestData.victor,
            inline = true
        },
        {
            name = 'Gang',
            value = conquestData.gang or 'Independent',
            inline = true
        },
        {
            name = 'Method',
            value = conquestData.method or 'Turf War',
            inline = true
        },
        {
            name = 'Bonus - Payout Boost',
            value = (conquestData.bonuses and conquestData.bonuses.dealer_payout_boost) and '+' .. math.floor((conquestData.bonuses.dealer_payout_boost * 100)) .. '%' or 'N/A',
            inline = true
        },
        {
            name = 'Bonus - Heat Reduction',
            value = (conquestData.bonuses and conquestData.bonuses.heat_reduction) and '-' .. conquestData.bonuses.heat_reduction .. ' heat/min' or 'N/A',
            inline = true
        }
    }
    
    SendDiscordEmbed(webhooks.territoryWars, title, description, colors.conquest, fields)
end

-- ========== AUCTION MILESTONES ==========

function LogAuctionMilestoneToDiscord(auctionData)
    if not logging.auctionMilestones or not webhooks.majorEvents then return end
    
    -- Only log high-value auctions
    if auctionData.finalPrice and auctionData.finalPrice < 50000 then
        return
    end
    
    local title = 'HIGH-VALUE AUCTION CLOSED'
    local description = auctionData.item.name .. ' sold for $' .. auctionData.finalPrice
    
    local fields = {
        {
            name = 'Item',
            value = auctionData.item.name,
            inline = true
        },
        {
            name = 'Rarity',
            value = auctionData.item.rarity or 'Unknown',
            inline = true
        },
        {
            name = 'Starting Price',
            value = '$' .. auctionData.startPrice,
            inline = true
        },
        {
            name = 'Final Price',
            value = '$' .. auctionData.finalPrice,
            inline = true
        },
        {
            name = 'Winner',
            value = auctionData.winner or 'No winner',
            inline = true
        },
        {
            name = 'Main Effect',
            value = auctionData.item.description or 'Special effects',
            inline = false
        }
    }
    
    SendDiscordEmbed(webhooks.majorEvents, title, description, colors.auction, fields)
end

-- ========== PLAYER MILESTONES ==========

function LogPlayerMilestoneToDiscord(milestoneData)
    if not logging.playerMilestones or not webhooks.majorEvents then return end
    
    local title = 'PLAYER MILESTONE'
    local description = ''
    
    if milestoneData.type == 'tier_up' then
        title = 'TIER PROMOTION'
        description = milestoneData.player .. ' reached ' .. milestoneData.tier .. '!'
    elseif milestoneData.type == 'reputation' then
        title = 'REPUTATION MILESTONE'
        description = milestoneData.player .. ' reached ' .. milestoneData.reputation .. ' reputation'
    elseif milestoneData.type == 'operation_count' then
        title = 'OPERATION MILESTONE'
        description = milestoneData.player .. ' completed ' .. milestoneData.count .. ' operations'
    elseif milestoneData.type == 'wealth' then
        title = 'WEALTH MILESTONE'
        description = milestoneData.player .. ' accumulated $' .. milestoneData.wealth
    end
    
    local fields = {
        {
            name = 'Player',
            value = milestoneData.player,
            inline = true
        },
        {
            name = 'Achievement',
            value = milestoneData.achievement or 'Major milestone',
            inline = true
        }
    }
    
    if milestoneData.details then
        table.insert(fields, {
            name = 'Details',
            value = milestoneData.details,
            inline = false
        })
    end
    
    SendDiscordEmbed(webhooks.majorEvents, title, description, colors.achievement, fields)
end

-- ========== ERROR REPORTING ==========

function LogErrorToDiscord(errorData)
    if not logging.criticalErrors or not webhooks.errors then return end
    
    local title = 'CRITICAL ERROR'
    local description = errorData.message or 'An error occurred'
    
    local fields = {
        {
            name = 'Error Type',
            value = errorData.type or 'Unknown',
            inline = true
        },
        {
            name = 'Severity',
            value = errorData.severity or 'MEDIUM',
            inline = true
        },
        {
            name = 'Source',
            value = errorData.source or 'Unknown',
            inline = false
        },
        {
            name = 'Stack Trace',
            value = errorData.trace and string.sub(errorData.trace, 1, 1024) or 'Not available',
            inline = false
        }
    }
    
    if errorData.affectedPlayers then
        table.insert(fields, {
            name = 'Affected Players',
            value = tostring(errorData.affectedPlayers),
            inline = true
        })
    end
    
    SendDiscordEmbed(webhooks.errors, title, description, colors.error, fields)
end

-- ========== FEEDBACK RELAY ==========

function LogFeedbackToDiscord(feedbackData)
    if not logging.playerFeedback or not webhooks.feedback then return end
    
    local title = 'PLAYER FEEDBACK - ' .. string.upper(feedbackData.category or 'OTHER')
    local description = feedbackData.feedback
    
    local fields = {
        {
            name = 'Player',
            value = feedbackData.player or 'Anonymous',
            inline = true
        },
        {
            name = 'Category',
            value = feedbackData.category or 'Other',
            inline = true
        },
        {
            name = 'Timestamp',
            value = os.date('%Y-%m-%d %H:%M:%S', os.time()),
            inline = true
        }
    }
    
    SendDiscordEmbed(webhooks.feedback, title, description, colors.feedback, fields)
end

-- ========== PUBLIC API ==========

exports('SendDiscordEmbed', SendDiscordEmbed)
exports('LogRaid', LogRaidToDiscord)
exports('LogTerritoryConquest', LogTerritoryConquestToDiscord)
exports('LogAuctionMilestone', LogAuctionMilestoneToDiscord)
exports('LogPlayerMilestone', LogPlayerMilestoneToDiscord)
exports('LogError', LogErrorToDiscord)
exports('LogFeedback', LogFeedbackToDiscord)

print('^2[DEA-Cartel] ^7Discord integration initialized^0')
