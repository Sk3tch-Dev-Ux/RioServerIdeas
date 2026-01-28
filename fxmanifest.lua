fx_version 'cerulean'
game 'gta5'

author 'DEA vs Cartel System'
description 'Dynamic faction-based drug production and territory control'
version '1.0.0'

shared_scripts {
    'config.lua',
    'shared/utils.lua'
}

server_scripts {
    'server/main.lua',
    'server/production.lua',
    'server/growth.lua',
    'server/sales.lua',
    'server/dea.lua',
    'server/dynamics.lua',
    'server/progression.lua',
    'server/auctions.lua',
    'server/territories.lua',
    'server/discord.lua',
    'server/feedback.lua'
}

client_scripts {
    'client/main.lua',
    'client/production.lua',
    'client/growth.lua',
    'client/sales.lua',
    'client/dea.lua',
    'client/dynamics.lua',
    'client/interactions.lua',
    'client/progression.lua',
    'client/dashboard.lua',
    'client/rules.lua',
    'client/feedback.lua'
}

dependencies {
    'qb-core',
    'ox_lib',
    'ox_target'
}
