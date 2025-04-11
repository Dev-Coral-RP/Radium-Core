local isNuiOpen = false

RegisterNetEvent('radium:spawn', function()
    local pos = Radium.Config.DefaultSpawn
    SetEntityCoords(PlayerPedId(), pos.x, pos.y, pos.z, false, false, false, true)
end)

RegisterNetEvent('radium:setNuiFocus')
AddEventHandler('radium:setNuiFocus', function(state)
    isNuiOpen = state
    SetNuiFocus(state, state)
    SetNuiFocusKeepInput(state)
end)

RegisterNetEvent('radium:showCharacterMenu', function(chars)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "showCharacterMenu",
        characters = chars
    })
end)

RegisterNetEvent("radium:spawnCharacter", function(char)
    -- Teleport or load appearance, etc. This is placeholder
    local ped = PlayerPedId()
    SetEntityCoords(ped, char.last_x, char.last_y, char.last_z, false, false, false, true)
    SetEntityHeading(ped, char.last_heading or 0.0)
end)


-- Disable HUD/Controls when not in NUI
CreateThread(function()
    while true do
        Wait(0)
        if not isNuiOpen then
            HideHudComponentThisFrame(1) -- Wanted Stars
            HideHudComponentThisFrame(2) -- Weapon Icon
            HideHudComponentThisFrame(3) -- Cash
            HideHudComponentThisFrame(4) -- MP Cash
            HideHudComponentThisFrame(13) -- HUD Help Text

            DisableControlAction(0, 37, true)  -- Weapon Wheel
            DisableControlAction(0, 199, true) -- Pause Menu Stats
        end
    end
end)


exports('getSharedObject', function()
    return Radium
end)

