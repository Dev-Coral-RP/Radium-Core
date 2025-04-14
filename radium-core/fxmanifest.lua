fx_version 'cerulean'
game 'gta5'

author 'DevCoral'
description 'Radium-Core Framework'
version '1.0.0'

shared_script '@ox_lib/init.lua'
shared_script 'shared/config.lua'

client_scripts {
    'client/main.lua',
    'client/modules/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/modules/multicharacter.lua',
    'server/modules/csn_utils.lua',
    'server/modules/logs.lua',
    'server/modules/appearance.lua',
    'exports/*.lua'
}

-- Optional: just a hint
dependency 'ox_lib'



lua54 'yes'