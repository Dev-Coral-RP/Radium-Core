fx_version 'cerulean'
game 'gta5'

lua54 'yes'

name 'radium-multicharacter'
description 'Multicharacter system built using ox_lib and oxmysql'
author 'YourName'

shared_script '@ox_lib/init.lua'

shared_script 'config.lua'

client_scripts {
    'config.lua',
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config.lua',
    'server/main.lua'
}


