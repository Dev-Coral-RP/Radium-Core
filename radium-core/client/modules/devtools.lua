print("[Radium-Core] Loaded Module: devtools.lua")

local showCoords = false

RegisterCommand("showcoords", function()
    showCoords = not showCoords
    print("[RadiumCore] ShowCoords:", showCoords and "ON" or "OFF")
end, false)

CreateThread(function()
    while true do
        Wait(0)
        if showCoords then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            local rot = GetEntityRotation(ped)

            local x = string.format("%.2f", coords.x)
            local y = string.format("%.2f", coords.y)
            local z = string.format("%.2f", coords.z)
            local h = string.format("%.2f", heading)

            local text = string.format("vec3(%s, %s, %s) heading: %s", x, y, z, h)
            DrawTextTopLeft(text)
        end
    end
end)

function DrawTextTopLeft(text)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextScale(0.35, 0.35)
    SetTextColour(0, 255, 0, 215)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(0.015, 0.015)
end
