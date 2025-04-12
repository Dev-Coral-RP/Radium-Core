-- radium-multicharacter/server/main.lua

lib.callback.register('radium-multicharacter:getCharacters', function(source)
    return exports['radium-core']:GetCharacters(source)
end)

RegisterNetEvent('radium-multicharacter:createCharacter', function(data)
    local src = source
    exports['radium-core']:CreateCharacter(src, data)

    -- Refresh UI
    local characters = exports['radium-core']:GetCharacters(src)
    TriggerClientEvent('radium-multicharacter:openUI', src, characters)
end)

RegisterNetEvent('radium-multicharacter:deleteCharacter', function(csn)
    local src = source
    exports['radium-core']:DeleteCharacter(src, csn)

    -- Refresh UI
    local characters = exports['radium-core']:GetCharacters(src)
    TriggerClientEvent('radium-multicharacter:openUI', src, characters)
end)

RegisterNetEvent('radium-multicharacter:loadCharacter', function(csn)
    local src = source
    exports['radium-core']:LoadCharacter(src, csn)

    -- Let client know to close UI
    TriggerClientEvent('radium-multicharacter:spawn', src)
end)
