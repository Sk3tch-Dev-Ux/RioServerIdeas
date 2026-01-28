local QBCore = exports['qb-core']:GetCoreObject()
local lib = exports.ox_lib

-- ========== FEEDBACK SUBMISSION ==========

function ShowFeedbackForm()
    if not Config.FeedbackSystem.enabled then
        return lib.notify({ title = 'Feedback unavailable', type = 'error' })
    end
    
    -- Step 1: Select category
    local categoryInput = lib.inputDialog('Submit Feedback', {
        {
            type = 'select',
            label = 'Feedback Category',
            description = 'What is your feedback about?',
            options = {
                { label = 'Balance', value = 'balance' },
                { label = 'Bugs/Glitches', value = 'bugs' },
                { label = 'Feature Suggestion', value = 'features' },
                { label = 'Difficulty', value = 'difficulty' },
                { label = 'UI/Menu', value = 'ui' },
                { label = 'Performance', value = 'performance' },
                { label = 'Other', value = 'other' }
            },
            required = true
        }
    })
    
    if not categoryInput then return end
    
    local category = categoryInput[1]
    
    -- Step 2: Enter feedback text
    local feedbackInput = lib.inputDialog('Submit Feedback', {
        {
            type = 'textarea',
            label = 'Your Feedback',
            description = 'Be specific and constructive (max ' .. Config.FeedbackSystem.collection.maxLength .. ' characters)',
            required = true
        }
    })
    
    if not feedbackInput then return end
    
    local feedbackText = feedbackInput[1]
    
    -- Validate
    if not feedbackText or #feedbackText == 0 then
        return lib.notify({ title = 'Feedback cannot be empty', type = 'error' })
    end
    
    if Config.FeedbackSystem.collection.characterLimit and #feedbackText > Config.FeedbackSystem.collection.maxLength then
        return lib.notify({ 
            title = 'Feedback too long', 
            description = 'Maximum ' .. Config.FeedbackSystem.collection.maxLength .. ' characters',
            type = 'error' 
        })
    end
    
    -- Step 3: Confirm and submit
    local confirm = lib.alertDialog({
        header = 'Confirm Submission',
        content = 'Category: ' .. category .. '\n\nFeedback:\n' .. feedbackText,
        centered = true,
        cancel = true
    })
    
    if confirm == 'confirm' then
        -- Submit to server
        TriggerServerEvent('dea-cartel:server:submitFeedback', feedbackText, category)
        
        lib.notify({
            title = 'Feedback Submitted',
            description = 'Thank you for your input!',
            type = 'success',
            duration = 3000
        })
    end
end

-- ========== QUICK FEEDBACK COMMANDS ==========

RegisterCommand('feedback', function(source, args, rawCommand)
    ShowFeedbackForm()
end, false)

RegisterCommand('reportbug', function(source, args, rawCommand)
    -- Quick bug report
    local feedbackInput = lib.inputDialog('Report Bug', {
        {
            type = 'textarea',
            label = 'Describe the bug',
            description = 'What is broken?',
            required = true
        }
    })
    
    if feedbackInput then
        TriggerServerEvent('dea-cartel:server:submitFeedback', feedbackInput[1], 'bugs')
    end
end, false)

RegisterCommand('suggest', function(source, args, rawCommand)
    -- Quick feature suggestion
    local feedbackInput = lib.inputDialog('Suggest Feature', {
        {
            type = 'textarea',
            label = 'Your suggestion',
            description = 'What feature would you like?',
            required = true
        }
    })
    
    if feedbackInput then
        TriggerServerEvent('dea-cartel:server:submitFeedback', feedbackInput[1], 'features')
    end
end, false)

-- ========== FEEDBACK MENU ==========

function ShowFeedbackMenu()
    local options = {
        {
            title = 'Player Feedback',
            description = 'Help us improve the server',
            disabled = true
        },
        {
            title = '---',
            disabled = true
        },
        {
            title = 'Submit Feedback',
            description = 'Share your thoughts on gameplay',
            icon = 'fas fa-comments',
            onSelect = function()
                ShowFeedbackForm()
            end
        },
        {
            title = 'Report a Bug',
            description = 'Tell us about issues you found',
            icon = 'fas fa-bug',
            onSelect = function()
                TriggerEvent('dea-cartel:client:quickBugReport')
            end
        },
        {
            title = 'Suggest a Feature',
            description = 'Propose new ideas or improvements',
            icon = 'fas fa-lightbulb',
            onSelect = function()
                TriggerEvent('dea-cartel:client:quickFeatureSuggest')
            end
        },
        {
            title = '---',
            disabled = true
        },
        {
            title = 'Feedback FAQ',
            description = 'Common questions about feedback',
            icon = 'fas fa-question-circle',
            onSelect = function()
                ShowFeedbackFAQ()
            end
        }
    }
    
    lib.registerContext({
        id = 'feedback_menu',
        title = 'Feedback System',
        options = options
    })
    
    lib.showContext('feedback_menu')
end

-- ========== FAQ ==========

function ShowFeedbackFAQ()
    local options = {
        {
            title = 'Feedback FAQ',
            description = 'Frequently asked questions',
            disabled = true
        },
        {
            title = '---',
            disabled = true
        },
        {
            title = 'How is feedback used?',
            description = 'Feedback is reviewed by admins and incorporated into balance updates',
            icon = 'fas fa-lightbulb'
        },
        {
            title = 'Will my feedback be seen?',
            description = 'Yes! All feedback is logged and reviewed regularly',
            icon = 'fas fa-check'
        },
        {
            title = 'How often can I submit?',
            description = 'You can submit once every 5 minutes',
            icon = 'fas fa-clock'
        },
        {
            title = 'Can I stay anonymous?',
            description = 'Anonymous feedback is not enabled for quality control',
            icon = 'fas fa-mask'
        },
        {
            title = 'What makes good feedback?',
            description = 'Be specific, constructive, and explain your reasoning',
            icon = 'fas fa-pen'
        },
        {
            title = 'Where do I report serious issues?',
            description = 'Use /reportbug for bugs or message staff on Discord',
            icon = 'fas fa-phone'
        }
    }
    
    lib.registerContext({
        id = 'feedback_faq_menu',
        title = 'FAQ',
        menu = 'feedback_menu',
        options = options
    })
    
    lib.showContext('feedback_faq_menu')
end

-- ========== LOCAL EVENTS ==========

RegisterNetEvent('dea-cartel:client:quickBugReport', function()
    local input = lib.inputDialog('Quick Bug Report', {
        {
            type = 'textarea',
            label = 'Bug Description',
            required = true
        }
    })
    
    if input then
        TriggerServerEvent('dea-cartel:server:submitFeedback', input[1], 'bugs')
    end
end)

RegisterNetEvent('dea-cartel:client:quickFeatureSuggest', function()
    local input = lib.inputDialog('Feature Suggestion', {
        {
            type = 'textarea',
            label = 'Your Suggestion',
            required = true
        }
    })
    
    if input then
        TriggerServerEvent('dea-cartel:server:submitFeedback', input[1], 'features')
    end
end)

-- ========== FEEDBACK STATS (ADMIN) ==========

RegisterNetEvent('dea-cartel:client:feedbackStatsReceived', function(stats)
    local options = {
        {
            title = 'Feedback Statistics',
            description = 'Session: ' .. stats.thisSession .. ' submissions',
            disabled = true
        },
        {
            title = '---',
            disabled = true
        },
        {
            title = 'Total Feedback',
            description = stats.total,
            icon = 'fas fa-chart-bar',
            disabled = true
        }
    }
    
    -- Add category breakdown
    if stats.byCategory and next(stats.byCategory) then
        table.insert(options, {
            title = '---',
            disabled = true
        })
        
        table.insert(options, {
            title = 'By Category',
            disabled = true
        })
        
        for category, count in pairs(stats.byCategory) do
            table.insert(options, {
                title = category,
                description = count .. ' feedback',
                disabled = true
            })
        end
    end
    
    lib.registerContext({
        id = 'feedback_stats_menu',
        title = 'Feedback Stats',
        options = options
    })
    
    lib.showContext('feedback_stats_menu')
end)

RegisterNetEvent('dea-cartel:client:viewFeedbackUI', function()
    ShowFeedbackMenu()
end)

print('^2[DEA-Cartel] ^7Feedback UI loaded^0')
