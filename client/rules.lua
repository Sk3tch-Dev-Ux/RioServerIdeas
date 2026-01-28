local QBCore = exports['qb-core']:GetCoreObject()
local lib = exports.ox_lib

-- ========== SERVER RULES & GUIDELINES ==========

function ShowServerRules()
    if not Config.ServerRules.enabled then
        return lib.notify({ title = 'Rules unavailable', type = 'error' })
    end
    
    local options = {
        {
            title = 'DEA vs Cartel - Server Rules',
            description = 'Version 1.0.0',
            disabled = true
        },
        {
            title = '---',
            disabled = true
        }
    }
    
    -- Add all rules
    for i, rule in ipairs(Config.ServerRules.rules) do
        table.insert(options, {
            title = rule.title,
            description = '[' .. rule.severity .. ']',
            icon = 'fas fa-info-circle',
            onSelect = function()
                ShowRuleDetails(rule)
            end
        })
    end
    
    table.insert(options, {
        title = '---',
        disabled = true
    })
    
    table.insert(options, {
        title = 'Role Guidelines',
        description = 'Learn about your faction',
        icon = 'fas fa-book',
        onSelect = function()
            ShowRoleGuidelines()
        end
    })
    
    lib.registerContext({
        id = 'server_rules_menu',
        title = 'Server Rules',
        options = options
    })
    
    lib.showContext('server_rules_menu')
end

function ShowRuleDetails(rule)
    local options = {
        {
            title = rule.title,
            description = 'Severity: ' .. rule.severity,
            disabled = true
        },
        {
            title = '---',
            disabled = true
        },
        {
            title = 'Description',
            disabled = true
        },
        {
            title = rule.description,
            disabled = true
        },
        {
            title = '---',
            disabled = true
        }
    }
    
    -- Add consequences based on severity
    if rule.severity == 'HIGH' then
        table.insert(options, {
            title = 'Violations may result in:',
            description = 'Warnings, restrictions, or bans',
            icon = 'fas fa-exclamation-triangle',
            disabled = true
        })
    elseif rule.severity == 'MEDIUM' then
        table.insert(options, {
            title = 'Violations may result in:',
            description = 'Warnings or temporary restrictions',
            icon = 'fas fa-exclamation',
            disabled = true
        })
    else
        table.insert(options, {
            title = 'Violations may result in:',
            description = 'Informal warnings',
            icon = 'fas fa-info-circle',
            disabled = true
        })
    end
    
    table.insert(options, {
        title = '---',
        disabled = true
    })
    
    table.insert(options, {
        title = 'Questions?',
        description = 'Check the Discord or ask a staff member',
        icon = 'fas fa-question-circle'
    })
    
    lib.registerContext({
        id = 'rule_detail_' .. rule.title,
        title = rule.title,
        menu = 'server_rules_menu',
        options = options
    })
    
    lib.showContext('rule_detail_' .. rule.title)
end

-- ========== ROLE GUIDELINES ==========

function ShowRoleGuidelines()
    local options = {
        {
            title = 'Faction Guidelines',
            description = 'Choose your role to learn more',
            disabled = true
        },
        {
            title = '---',
            disabled = true
        }
    }
    
    -- Add cartel guidelines
    local cartelGuide = Config.ServerRules.guidelines.cartel
    table.insert(options, {
        title = cartelGuide.name,
        description = 'Criminal organization',
        icon = 'fas fa-cannabis',
        onSelect = function()
            ShowDetailedGuideline(cartelGuide)
        end
    })
    
    -- Add DEA guidelines
    local deaGuide = Config.ServerRules.guidelines.dea
    table.insert(options, {
        title = deaGuide.name,
        description = 'Federal law enforcement',
        icon = 'fas fa-shield-alt',
        onSelect = function()
            ShowDetailedGuideline(deaGuide)
        end
    })
    
    -- Add neutral guidelines
    local neutralGuide = Config.ServerRules.guidelines.neutral
    table.insert(options, {
        title = neutralGuide.name,
        description = 'Independent operator',
        icon = 'fas fa-person',
        onSelect = function()
            ShowDetailedGuideline(neutralGuide)
        end
    })
    
    lib.registerContext({
        id = 'role_guidelines_menu',
        title = 'Faction Guidelines',
        menu = 'server_rules_menu',
        options = options
    })
    
    lib.showContext('role_guidelines_menu')
end

function ShowDetailedGuideline(guide)
    local options = {
        {
            title = guide.name,
            description = 'Detailed guidelines and restrictions',
            disabled = true
        },
        {
            title = '---',
            disabled = true
        },
        {
            title = 'Description',
            disabled = true
        },
        {
            title = guide.description,
            disabled = true
        },
        {
            title = '---',
            disabled = true
        },
        {
            title = 'Responsibilities',
            disabled = true
        }
    }
    
    -- Add responsibilities
    for i, responsibility in ipairs(guide.responsibilities) do
        table.insert(options, {
            title = '• ' .. responsibility,
            disabled = true
        })
    end
    
    table.insert(options, {
        title = '---',
        disabled = true
    })
    
    table.insert(options, {
        title = 'Restrictions',
        disabled = true
    })
    
    -- Add restrictions
    for i, restriction in ipairs(guide.restrictions) do
        table.insert(options, {
            title = '• ' .. restriction,
            disabled = true
        })
    end
    
    lib.registerContext({
        id = 'guideline_' .. guide.name,
        title = guide.name,
        menu = 'role_guidelines_menu',
        options = options
    })
    
    lib.showContext('guideline_' .. guide.name)
end

-- ========== SERVER INFO ==========

function ShowServerInfo()
    local status = 'CLOSED BETA'
    if Config.ServerInfo.launchStatus == 'OPEN_BETA' then
        status = 'OPEN BETA'
    elseif Config.ServerInfo.launchStatus == 'LAUNCH' then
        status = 'LAUNCHING SOON'
    elseif Config.ServerInfo.launchStatus == 'LIVE' then
        status = 'LIVE'
    end
    
    local options = {
        {
            title = Config.ServerInfo.name,
            description = 'Version ' .. Config.ServerInfo.version,
            disabled = true
        },
        {
            title = '---',
            disabled = true
        },
        {
            title = 'Status',
            description = status,
            icon = 'fas fa-circle',
            disabled = true
        },
        {
            title = 'Phase',
            description = Config.ServerInfo.phase,
            icon = 'fas fa-rocket',
            disabled = true
        },
        {
            title = 'Max Players',
            description = Config.ServerInfo.maxPlayers,
            icon = 'fas fa-users',
            disabled = true
        },
        {
            title = 'Launch Date',
            description = Config.ServerInfo.estimatedLaunchDate,
            icon = 'fas fa-calendar',
            disabled = true
        },
        {
            title = '---',
            disabled = true
        },
        {
            title = 'Join Discord',
            description = 'Get updates and support',
            icon = 'fas fa-discord',
            onSelect = function()
                lib.notify({ 
                    title = 'Discord', 
                    description = 'Copy the link from server info',
                    type = 'info'
                })
            end
        },
        {
            title = 'Available Features',
            description = 'View enabled systems',
            icon = 'fas fa-star',
            onSelect = function()
                ShowFeatureList()
            end
        }
    }
    
    lib.registerContext({
        id = 'server_info_menu',
        title = 'Server Information',
        options = options
    })
    
    lib.showContext('server_info_menu')
end

function ShowFeatureList()
    local options = {
        {
            title = 'Available Features',
            description = 'Currently enabled systems',
            disabled = true
        },
        {
            title = '---',
            disabled = true
        }
    }
    
    if Config.ServerInfo.features.drugProduction then
        table.insert(options, {
            title = 'Drug Production',
            description = 'Grow houses and labs',
            icon = 'fas fa-leaf',
            disabled = true
        })
    end
    
    if Config.ServerInfo.features.turf_wars then
        table.insert(options, {
            title = 'Territory Control',
            description = 'Claim territories, turf wars',
            icon = 'fas fa-flag',
            disabled = true
        })
    end
    
    if Config.ServerInfo.features.auctions then
        table.insert(options, {
            title = 'Black Market Auctions',
            description = 'Bid on rare items',
            icon = 'fas fa-gavel',
            disabled = true
        })
    end
    
    if Config.ServerInfo.features.progressionSystem then
        table.insert(options, {
            title = 'Progression System',
            description = '4-tier reputation system',
            icon = 'fas fa-chart-line',
            disabled = true
        })
    end
    
    if Config.ServerInfo.features.deaMechanics then
        table.insert(options, {
            title = 'DEA Mechanics',
            description = 'Heat system, raids, evasion',
            icon = 'fas fa-shield-alt',
            disabled = true
        })
    end
    
    lib.registerContext({
        id = 'feature_list_menu',
        title = 'Features',
        menu = 'server_info_menu',
        options = options
    })
    
    lib.showContext('feature_list_menu')
end

-- ========== COMMANDS ==========

RegisterCommand('rules', function(source, args, rawCommand)
    ShowServerRules()
end, false)

RegisterCommand('serverinfo', function(source, args, rawCommand)
    ShowServerInfo()
end, false)

RegisterCommand('guidelines', function(source, args, rawCommand)
    ShowRoleGuidelines()
end, false)

print('^2[DEA-Cartel] ^7Server rules system loaded^0')
