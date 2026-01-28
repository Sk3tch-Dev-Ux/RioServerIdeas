local QBCore = exports['qb-core']:GetCoreObject()

-- ========== FEEDBACK SYSTEM ==========

PlayerFeedbackCooldown = {}  -- Track cooldowns per player

-- ========== SUBMIT FEEDBACK ==========

RegisterNetEvent('dea-cartel:server:submitFeedback', function(feedbackText, category)
    local source = source
    local player = QBCore.Functions.GetPlayer(source)
    
    if not player then return end
    
    -- Check if feedback system enabled
    if not Config.FeedbackSystem.enabled then
        return TriggerClientEvent('QBCore:Notify', source, 'Feedback system is disabled', 'error')
    end
    
    -- Validate input
    if not feedbackText or feedbackText == '' then
        return TriggerClientEvent('QBCore:Notify', source, 'Feedback cannot be empty', 'error')
    end
    
    if Config.FeedbackSystem.collection.characterLimit and #feedbackText > Config.FeedbackSystem.collection.maxLength then
        return TriggerClientEvent('QBCore:Notify', source, 'Feedback too long (max ' .. Config.FeedbackSystem.collection.maxLength .. ' characters)', 'error')
    end
    
    -- Check cooldown
    if PlayerFeedbackCooldown[source] and os.time() < PlayerFeedbackCooldown[source] then
        local timeLeft = math.ceil(PlayerFeedbackCooldown[source] - os.time())
        return TriggerClientEvent('QBCore:Notify', source, 'Please wait ' .. timeLeft .. 's before submitting again', 'error')
    end
    
    -- Validate category
    if not category or category == '' then
        category = 'other'
    end
    
    -- Store feedback
    local feedbackData = {
        id = math.random(100000, 999999),
        player = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
        citizenid = player.PlayerData.citizenid,
        source = source,
        feedback = feedbackText,
        category = category,
        timestamp = os.date('%Y-%m-%d %H:%M:%S', os.time()),
        rating = nil
    }
    
    -- Auto-categorize if needed
    if not category or category == '' then
        feedbackData.category = AutoCategorizeFeedback(feedbackText)
    end
    
    -- Log to Discord
    exports['dea-cartel']:LogFeedback(feedbackData)
    
    -- Save to database or file
    SaveFeedback(feedbackData)
    
    -- Set cooldown
    PlayerFeedbackCooldown[source] = os.time() + (Config.FeedbackSystem.moderation.cooldownBetweenSubmissions / 1000)
    
    -- Notify player
    TriggerClientEvent('QBCore:Notify', source, 'Feedback submitted successfully! Thank you!', 'success')
    
    -- Log to console
    print('^3[Feedback] ' .. feedbackData.player .. ' (ID: ' .. feedbackData.id .. '): ' .. feedbackData.feedback .. '^0')
end)

-- ========== AUTO-CATEGORIZATION ==========

function AutoCategorizeFeedback(text)
    local lowerText = string.lower(text)
    
    for category, keywords in pairs(Config.FeedbackSystem.collection.keywords) do
        for _, keyword in ipairs(keywords) do
            if string.find(lowerText, string.lower(keyword)) then
                return category
            end
        end
    end
    
    return 'other'
end

-- ========== SAVE FEEDBACK ==========

function SaveFeedback(feedbackData)
    if Config.FeedbackSystem.storage == 'file' then
        SaveFeedbackToFile(feedbackData)
    else
        SaveFeedbackToDatabase(feedbackData)
    end
end

function SaveFeedbackToFile(feedbackData)
    local filePath = Config.FeedbackSystem.filePath .. 'feedback_' .. os.date('%Y%m%d', os.time()) .. '.json'
    
    -- Read existing feedback
    local existingData = {}
    local file = io.open(filePath, 'r')
    if file then
        local content = file:read('*a')
        file:close()
        
        if content and content ~= '' then
            existingData = json.decode(content)
        end
    end
    
    -- Add new feedback
    table.insert(existingData, feedbackData)
    
    -- Write back
    file = io.open(filePath, 'w')
    if file then
        file:write(json.encode(existingData, {indent = true}))
        file:close()
    end
end

function SaveFeedbackToDatabase(feedbackData)
    -- Implementation depends on your database
    -- Example for MySQL/MariaDB:
    -- INSERT INTO feedback (id, player, citizenid, feedback, category, timestamp) VALUES (...)
    
    -- For now, just log
    print('^2[Feedback Saved] ' .. feedbackData.id .. ' - ' .. feedbackData.category .. '^0')
end

-- ========== GET FEEDBACK STATS ==========

RegisterNetEvent('dea-cartel:server:getFeedbackStats', function()
    local source = source
    local player = QBCore.Functions.GetPlayer(source)
    
    if not player then return end
    
    -- Only admins can view this
    if not IsPlayerAdmin(source) then
        return TriggerClientEvent('QBCore:Notify', source, 'You do not have permission to view feedback stats', 'error')
    end
    
    local stats = {
        total = GetTotalFeedbackCount(),
        byCateogry = GetFeedbackByCategory(),
        recent = GetRecentFeedback(10),
        thisSession = GetSessionFeedbackCount()
    }
    
    TriggerClientEvent('dea-cartel:client:feedbackStatsReceived', source, stats)
end)

function GetTotalFeedbackCount()
    -- Count feedback files/records
    -- Implementation depends on storage method
    return 0  -- Placeholder
end

function GetFeedbackByCategory()
    -- Group feedback by category
    -- Implementation depends on storage method
    return {}  -- Placeholder
end

function GetRecentFeedback(limit)
    -- Get most recent feedback
    -- Implementation depends on storage method
    return {}  -- Placeholder
end

function GetSessionFeedbackCount()
    -- Count feedback in current session
    local count = 0
    for _, cooldown in pairs(PlayerFeedbackCooldown) do
        count = count + 1
    end
    return count
end

-- ========== ADMIN COMMANDS ==========

RegisterCommand('viewfeedback', function(source, args, rawCommand)
    if not IsPlayerAdmin(source) then
        return TriggerClientEvent('QBCore:Notify', source, 'You do not have permission', 'error')
    end
    
    TriggerClientEvent('dea-cartel:client:viewFeedbackUI', source)
end, false)

RegisterCommand('feedbackstats', function(source, args, rawCommand)
    if not IsPlayerAdmin(source) then
        return TriggerClientEvent('QBCore:Notify', source, 'You do not have permission', 'error')
    end
    
    TriggerServerEvent('dea-cartel:server:getFeedbackStats')
end, false)

-- ========== HELPER ==========

function IsPlayerAdmin(source)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false end
    
    -- Check if player has admin permission (depends on your framework)
    -- This is a simplified check
    return player.PlayerData.job.isboss or player.PlayerData.job.name == 'police'  -- Adjust as needed
end

print('^2[DEA-Cartel] ^7Feedback system initialized^0')
