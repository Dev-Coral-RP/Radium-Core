fx_version 'cerulean'
game 'gta5'

author 'DevCoral'
description 'Radium Core Framework'
version '1.0.0'

shared_scripts {
    'shared/config.lua',
    'shared/utils.lua',
    'shared/player.lua',
    
}

server_scripts {
    'server/*.lua',
    
}

client_scripts{
   'client/*.lua',
}

dependencies {
    'oxmysql'
}
