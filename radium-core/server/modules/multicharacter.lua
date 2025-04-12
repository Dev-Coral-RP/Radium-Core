RegisterNetEvent('radium-core:playerReady', function()
    local src = source
    if Config.MultiCharacter then
        local characters = exports['radium-core']:GetCharacters(src)
        TriggerClientEvent('radium-multicharacter:openUI', src, characters)
    end
end)
