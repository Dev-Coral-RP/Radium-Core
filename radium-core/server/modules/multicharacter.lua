print("[Radium-Core] Loaded: multicharacter.lua")

RegisterNetEvent('radium-core:playerReady', function(src)
    src = src or source
    print("[Radium-Core] PlayerReady Event Triggered for ID:", src)

    if Config.MultiCharacter then
        local characters = exports['radium-core']:GetCharacters(src)
        print("[Radium-Core] Found characters:", json.encode(characters))
        TriggerClientEvent('radium-multicharacter:openUI', src, characters)
    end
end)


