print("[Radium-Core] Loaded Module: character.lua")

if Config.useExternalCharacters then
    return -- Skip internal multicharacter if external system is enabled
end

QBX = QBX or {}
QBX.PlayerData = QBX.PlayerData or {}

RegisterNetEvent('radium-core:client:setPlayerData', function(data)
    if type(data) == 'table' then
        QBX.PlayerData = data
    end
end)

-- Camera setup for character preview
local previewCam = nil
local previewCamPos = vector3(-1035.71, -2738.87, 14.5)
local previewPedPos = vector4(-1035.71, -2731.87, 13.0, 0.0)

local maleModel = joaat("mp_m_freemode_01")
local femaleModel = joaat("mp_f_freemode_01")

local function loadPreviewPed(gender)
    local model = gender == 1 and femaleModel or maleModel
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end
    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)
    local ped = PlayerPedId()
    SetEntityCoords(ped, previewPedPos.x, previewPedPos.y, previewPedPos.z, false, false, false, true)
    SetEntityHeading(ped, previewPedPos.w)
    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, true, false)

    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    DoScreenFadeIn(500)

    return ped
end

local function setupPreviewCam()
    previewCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(previewCam, previewCamPos.x, previewCamPos.y, previewCamPos.z)
    PointCamAtCoord(previewCam, previewPedPos.x, previewPedPos.y, previewPedPos.z + 0.5)
    SetCamActive(previewCam, true)
    SetCamFov(previewCam, 40.0)
    RenderScriptCams(true, false, 0, true, true)
    SetTimecycleModifier("hud_def_blur")
end

local function destroyPreviewCam()
    if previewCam then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(previewCam, false)
        previewCam = nil
        ClearTimecycleModifier()
    end
end

local function confirmDelete(name)
    local alert = lib.alertDialog({
        header = 'Delete Character',
        content = 'Are you sure you want to delete **'..name..'**? This cannot be undone.',
        centered = true,
        cancel = true
    })
    return alert == 'confirm'
end

local function spawnDefault()
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end
    local pos = Config.SpawnLocation
    local spawnCoords = (type(pos) == 'vector4') and pos or vector4(pos.x or 0.0, pos.y or 0.0, pos.z or 0.0, pos.w or 0.0)
    exports.spawnmanager:spawnPlayer({
        x = spawnCoords.x,
        y = spawnCoords.y,
        z = spawnCoords.z,
        heading = spawnCoords.w
    }, function()
        FreezeEntityPosition(PlayerPedId(), false)
        SetEntityVisible(PlayerPedId(), true, false)
        NetworkEndTutorialSession()
        DoScreenFadeIn(1000)
        TriggerServerEvent('Radium:Server:OnPlayerLoaded')

        NetworkEndTutorialSession()
        destroyPreviewCam()
        DoScreenFadeIn(1000)
        SetPedComponentVariation(PlayerPedId(), 11, 0, 0, 2) -- basic torso just to ensure clothes show


    end)
end

local function spawnLastLocation()
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end
    local pos = QBX.PlayerData.position or {}
    local spawnCoords
    if pos.x and pos.y and pos.z then
        spawnCoords = vector4(pos.x, pos.y, pos.z, pos.w or 0.0)
    else
        local def = Config.SpawnLocation
        spawnCoords = (type(def) == 'vector4') and def or vector4(def.x or 0.0, def.y or 0.0, def.z or 0.0, def.w or 0.0)
    end
    exports.spawnmanager:spawnPlayer({
        x = spawnCoords.x,
        y = spawnCoords.y,
        z = spawnCoords.z,
        heading = spawnCoords.w
    }, function()
        FreezeEntityPosition(PlayerPedId(), false)
        SetEntityVisible(PlayerPedId(), true, false)
        NetworkEndTutorialSession()
        DoScreenFadeIn(1000)
        TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
        TriggerEvent('QBCore:Client:OnPlayerLoaded')
        TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
        TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)

        NetworkEndTutorialSession()
        destroyPreviewCam()
        DoScreenFadeIn(1000)

    end)
end

local function openCreateCharacter(slot)
    local input = lib.inputDialog('Create New Character', {
        { type = 'input', label = 'First Name', placeholder = 'First Name', required = true, min = 2, max = 25 },
        { type = 'input', label = 'Last Name',  placeholder = 'Last Name',  required = true, min = 2, max = 25 },
        { type = 'select', label = 'Gender', options = { {label = 'Male', value = 0}, {label = 'Female', value = 1} }, required = true },
        { type = 'input', label = 'Date of Birth', description = 'Format: YYYY-MM-DD', placeholder = 'YYYY-MM-DD', required = true },
        { type = 'select', label = 'Blood Type', options = {
            {label = 'A+',  value = 'A+'},  {label = 'A-',  value = 'A-'},
            {label = 'B+',  value = 'B+'},  {label = 'B-',  value = 'B-'},
            {label = 'AB+', value = 'AB+'}, {label = 'AB-', value = 'AB-'},
            {label = 'O+',  value = 'O+'},  {label = 'O-',  value = 'O-'}
        }, required = true }
    })
    if not input then return false end
    local fname, lname = input[1], input[2]
    local genderVal = tonumber(input[3]) or 0
    local birthdate = input[4]
    local bloodType = input[5]

    local newId = lib.callback.await('radium-core:server:createCharacter', false, {
        firstname = fname,
        lastname  = lname,
        gender    = genderVal,
        birthdate = birthdate,
        blood     = bloodType,
        cid       = slot
    })
    if not newId then return false end
    spawnDefault()
    return true
end

local function spawnAtLocation(coords)
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end
    exports.spawnmanager:spawnPlayer({
        x = coords.x,
        y = coords.y,
        z = coords.z,
        heading = coords.w
    }, function()
        FreezeEntityPosition(PlayerPedId(), false)
        SetEntityVisible(PlayerPedId(), true, false)
        destroyPreviewCam()
        NetworkEndTutorialSession()
        DoScreenFadeIn(1000)
    end)
end

local function openSpawnSelector()
    local options = {
        { title = "Last Location", value = "last" },
        { title = "LSIA Terminal", value = "lsia" },
        { title = "Legion Square", value = "legion" }
    }

    -- Example: Add job-locked location
    if QBX.PlayerData.job == "police" then
        table.insert(options, { title = "MRPD", value = "mrpd" })
    end

    local choice = lib.inputDialog("Choose Spawn Location", {
        {
            type = "select",
            label = "Location",
            options = options,
            required = true
        }
    })

    if not choice then return end

    local selection = choice[1]
    if selection == "last" then
        spawnLastLocation()
    elseif selection == "lsia" then
        spawnAtLocation(vector4(-1037.0, -2737.0, 13.8, 330.0))
    elseif selection == "legion" then
        spawnAtLocation(vector4(215.8, -810.0, 31.0, 160.0))
    elseif selection == "mrpd" then
        spawnAtLocation(vector4(440.84, -983.14, 30.69, 90.0))
    end
end



local function openCharacterSelection()
    local characters, maxSlots = lib.callback.await('radium-core:server:getCharacters', false)
    characters = characters or {}
    maxSlots = tonumber(maxSlots) or (Config.DefaultNumberOfCharacters or 1)

    local ped = loadPreviewPed(0)
    setupPreviewCam()
    NetworkStartSoloTutorialSession()
    while not NetworkIsInTutorialSession() do Wait(0) end

    local options = {}
    for i = 1, maxSlots do
        local char = nil
        for _, v in ipairs(characters) do
            if v.cid == i then char = v break end
        end
        if char then
            local info = char.charinfo or {}
            local name = (info.firstname and info.lastname) and (info.firstname .. ' ' .. info.lastname) or char.name or ('Character '..i)
            local genderLabel = (char.gender == 0) and 'Male' or 'Female'
            local dob = char.birthdate or info.birthdate or 'Unknown'
            local blood = char.blood or info.blood or 'N/A'
            local csn = char.csn or (info.csn or char.citizenid)
            local subMenuId = 'radium_char_opts_'..i
            lib.registerContext({ id = subMenuId, title = name..' - Options', menu = 'radium_characters', canClose = false,
                options = {
                    { title = 'Play', icon = 'play', description = 'Select this character',
                        onSelect = function()
                            DoScreenFadeOut(10)
                            local ok = lib.callback.await('radium-core:server:loadCharacter', false, char.citizenid)
                            if ok then spawnLastLocation() else lib.showContext('radium_characters') end
                        end
                    },
                    Config.EnableDeleteCharacter and {
                        title = 'Delete', icon = 'trash', description = 'Delete this character',
                        onSelect = function()
                            if confirmDelete(name) then
                                TriggerServerEvent('radium-core:server:deleteCharacter', char.citizenid)
                                Wait(500)
                                openCharacterSelection()
                            else
                                lib.showContext(subMenuId)
                            end
                        end
                    } or nil
                }
            })
            options[#options+1] = { title = string.format("%s [%s]", name, csn), description = string.format("DOB: %s | Gender: %s | Blood: %s", dob, genderLabel, blood), icon = 'user', menu = subMenuId, canClose = false, onSelect = function() lib.showContext(subMenuId) end }
        else
            options[#options+1] = {
                title = 'Empty Slot '..i,
                description = 'Create a new character',
                icon = 'plus',
                onSelect = function()
                    local created = openCreateCharacter(i)
                    if not created then lib.showContext('radium_characters') end
                end
            }
        end
    end

    lib.registerContext({ id = 'radium_characters', title = 'Character Selection', options = options, canClose = false })
    lib.showContext('radium_characters')
end

RegisterNetEvent('radium-core:client:openSelection', function()
    openCharacterSelection()
end)


CreateThread(function()
    pcall(function() exports.spawnmanager:setAutoSpawn(false) end)
    while not NetworkIsSessionStarted() do Wait(0) end
    Wait(250)
    openCharacterSelection()
end)
