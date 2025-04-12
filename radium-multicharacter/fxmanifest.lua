fx_version 'cerulean'
game 'gta5'

author 'YourName'
description 'Radium Multicharacter UI for Radium-Core'
version '1.0.0'

lua54 'yes'

shared_script '@ox_lib/init.lua'

client_script 'client/main.lua'
server_script 'server/main.lua'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}
