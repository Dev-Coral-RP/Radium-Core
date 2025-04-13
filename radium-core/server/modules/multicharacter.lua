print("[Radium-Core] Loaded: multicharacter.lua")

RegisterNetEvent('radium-core:playerReady', function(src)
    local characters = lib.callback.await('radium-multicharacter:getCharacters', src)
    TriggerClientEvent('radium-multicharacter:openMenu', src, characters)
end)



