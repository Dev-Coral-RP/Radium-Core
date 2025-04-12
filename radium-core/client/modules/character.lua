print("[Radium-Core] Loaded Module: character.lua")

RegisterNetEvent('radium-core:spawnCharacter', function(data)
    DoScreenFadeOut(500)
    Wait(500)

    SetEntityVisible(PlayerPedId(), true)
    SetEntityCoordsNoOffset(PlayerPedId(), data.spawn.x, data.spawn.y, data.spawn.z, false, false, false)
    SetEntityHeading(PlayerPedId(), data.spawn.w or 0.0)

    DoScreenFadeIn(1000)
    TriggerEvent('radium-notify:send', { text = "Welcome, " .. data.name, type = 'success' })
end)
