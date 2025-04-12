print("[Radium-Multicharacter] Client script loaded!")
local cam = nil
local peds = {}

-- NUI unblocker
CreateThread(function()
    while true do
        Wait(500)
        if not IsNuiFocused() then
            SetNuiFocus(false, false)
        end
    end
end)



RegisterNetEvent('radium-multicharacter:openUI', function(characters)
    print("[Radium-Multicharacter] Received UI open event!")
    print("[Radium-Multicharacter] Characters:", json.encode(characters))

    DoScreenFadeOut(0)
    SetEntityVisible(PlayerPedId(), false)

    -- Spawn preview peds
    spawnPreviewPeds(characters)

    -- Camera Setup
    cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(cam, -1037.72, -2738.36, 22.17)
    PointCamAtCoord(cam, -1037.72, -2738.36, 20.17)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 1000, true, true)

    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    DoScreenFadeIn(1000)

    -- Open UI
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openUI",
        characters = characters
    })
end)


RegisterNUICallback("createCharacter", function(data, cb)
    TriggerServerEvent('radium-multicharacter:createCharacter', data)
    cb(true)
end)

RegisterNUICallback("deleteCharacter", function(data, cb)
    TriggerServerEvent('radium-multicharacter:deleteCharacter', data.csn)
    cb(true)
end)

RegisterNUICallback("selectCharacter", function(data, cb)
    TriggerServerEvent('radium-multicharacter:loadCharacter', data.csn)
    cb(true)
end)

RegisterNetEvent('radium-multicharacter:spawn', function()
    DoScreenFadeOut(500)
    Wait(500)

    SetEntityVisible(PlayerPedId(), true)
    DestroyCam(cam, false)
    RenderScriptCams(false, true, 500, true, true)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "closeUI" })

    DoScreenFadeIn(1000)
end)


local previewSpots = {
    { x = -1037.72, y = -2738.36, z = 20.17, h = 328.68 },
    { x = -1033.50, y = -2742.12, z = 20.17, h = 328.68 },
    { x = -1029.38, y = -2745.98, z = 20.17, h = 328.68 }
}

local function spawnPreviewPeds(characters)
    for i = 1, Config.MaxSlots do
        local pedModel = characters[i] and `mp_m_freemode_01` or `a_m_m_bevhills_01`
        RequestModel(pedModel)
        while not HasModelLoaded(pedModel) do Wait(0) end

        local spot = previewSpots[i]
        local ped = CreatePed(4, pedModel, spot.x, spot.y, spot.z - 1.0, spot.h, false, true)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        table.insert(peds, ped)
    end
end



function deletePeds()
    for _, ped in pairs(peds) do
        DeleteEntity(ped)
    end
    peds = {}
end
