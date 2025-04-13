print("[Radium-Core] Loaded Server: main.lua")

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    deferrals.defer()
    Wait(100)

    deferrals.update("Loading Radium-Core...")
    Wait(100)

    deferrals.done()
    TriggerEvent('radium-core:playerReady', src)
end)

RegisterServerEvent('radium-multicharacter:open', function()
    local src = source
    TriggerClientEvent('radium-multicharacter:openMenu', src, characters)
end)
