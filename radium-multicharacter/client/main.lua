local cam
local previewPeds = {}
local MaxSlots = Config.MaxSlots or 3

-- Called on join
AddEventHandler('onClientResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        Wait(500)
        TriggerServerEvent('radium-multicharacter:open')
    end
end)


RegisterNetEvent('radium-multicharacter:openMenu', function(characters)
    setupCamera()
    spawnPreviewPeds(characters)

    local elements = {}

    for i = 1, MaxSlots do
        local char = characters[i]
        if char then
            elements[#elements+1] = {
                title = ('%s (Slot %s)'):format(char.name, char.slot),
                description = char.gender .. ' | ' .. char.dob,
                icon = 'user',
                onSelect = function()
                    lib.confirmDialog({
                        header = 'Play as this character?',
                        centered = true,
                        cancel = true,
                        labels = { confirm = 'Play', cancel = 'Back' }
                    }, function(confirm)
                        if confirm then
                            deletePreviewPeds()
                            camReset()
                            TriggerServerEvent('radium-multicharacter:selectCharacter', char.slot)
                        end
                    end)
                end,
                metadata = {
                    { label = 'CSN', value = char.csn },
                    { label = 'Blood', value = char.blood_type },
                },
                arrow = true
            }

            if Config.AllowCharacterDelete then
                elements[#elements].onRight = function()
                    lib.confirmDialog({
                        header = 'Delete this character?',
                        centered = true,
                        cancel = true,
                        labels = { confirm = 'Delete', cancel = 'Cancel' }
                    }, function(confirm)
                        if confirm then
                            TriggerServerEvent('radium-multicharacter:deleteCharacter', char.slot)
                            Wait(500)
                            TriggerServerEvent('radium-multicharacter:open') -- refresh
                        end
                    end)
                end
            end
        else
            elements[#elements+1] = {
                title = 'Empty Slot #' .. i,
                icon = 'plus',
                onSelect = function()
                    createNewCharacter(i)
                end
            }
        end
    end

    lib.registerContext({
        id = 'radium_multicharacter_menu',
        title = 'Select a Character',
        options = elements
    })

    lib.showContext('radium_multicharacter_menu')
end)

function createNewCharacter(slot)
    local input = lib.inputDialog('Create Character', {
        { type = 'input', label = 'Name', required = true },
        { type = 'select', label = 'Gender', options = {
            { label = 'Male', value = 'male' },
            { label = 'Female', value = 'female' }
        }, required = true },
        { type = 'input', label = 'DOB (YYYY-MM-DD)', required = true }
    })

    if not input then return end

    TriggerServerEvent('radium-multicharacter:createCharacter', {
        name = input[1],
        gender = input[2],
        dob = input[3],
        slot = slot
    })

    Wait(1000)
    TriggerServerEvent('radium-multicharacter:open') -- refresh
end

RegisterNetEvent('radium-multicharacter:spawnCharacter', function(data)
    DoScreenFadeOut(500)
    Wait(500)

    camReset()
    deletePreviewPeds()

    SetEntityCoordsNoOffset(PlayerPedId(), data.spawn.x, data.spawn.y, data.spawn.z, false, false, false)
    SetEntityHeading(PlayerPedId(), data.spawn.w)
    SetEntityVisible(PlayerPedId(), true)

    DoScreenFadeIn(1000)

    -- Welcome notify
    lib.notify({
        title = 'Welcome',
        description = ('%s (%s)'):format(data.name, data.csn),
        type = 'success'
    })
end)

function setupCamera()
    if cam then camReset() end

    cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(cam, Config.Camera.coords.x, Config.Camera.coords.y, Config.Camera.coords.z)
    PointCamAtCoord(cam, Config.Camera.lookAt.x, Config.Camera.lookAt.y, Config.Camera.lookAt.z)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 1000, true, true)
end

function camReset()
    if not cam then return end
    DestroyCam(cam, false)
    RenderScriptCams(false, true, 500, true, true)
    cam = nil
end

function spawnPreviewPeds(characters)
    for i = 1, MaxSlots do
        local spot = vector3(Config.Camera.lookAt.x + (i * 1.5), Config.Camera.lookAt.y, Config.Camera.lookAt.z)
        local model = characters[i] and `mp_m_freemode_01` or `a_m_m_bevhills_01`

        RequestModel(model)
        while not HasModelLoaded(model) do Wait(0) end

        local ped = CreatePed(4, model, spot.x, spot.y, spot.z - 1.0, 0.0, false, true)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        table.insert(previewPeds, ped)
    end
end

function deletePreviewPeds()
    for _, ped in pairs(previewPeds) do
        DeleteEntity(ped)
    end
    previewPeds = {}
end
