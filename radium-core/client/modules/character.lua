print("[Radium-Core] Loaded Module: character.lua")

if Config.useExternalCharacters then
    return -- Skip internal multicharacter if external system is enabled
end

-- Player data table (to store selected character info)
QBX = QBX or {}
QBX.PlayerData = QBX.PlayerData or {}

-- Listen for server-sent player data and store it
RegisterNetEvent('radium-core:client:setPlayerData', function(data)
    if type(data) == 'table' then
        QBX.PlayerData = data
    end
end)

-- Helper: confirmation dialog for deleting a character
local function confirmDelete(name)
    local alert = lib.alertDialog({
        header = 'Delete Character',
        content = 'Are you sure you want to delete **'..name..'**? This cannot be undone.',
        centered = true,
        cancel = true
    })
    return alert == 'confirm'
end

-- Spawn the player at the default spawn location (for new characters)
local function spawnDefault()
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end
    -- Determine spawn coordinates from Config
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
        NetworkEndTutorialSession()  -- end solo session, rejoin global network
        DoScreenFadeIn(1000)
        -- Notify other resources that player has loaded
        TriggerServerEvent('Radium:Server:OnPlayerLoaded')
        TriggerEvent('QBCore:Radium:Client:OnPlayerLoaded')
        -- Reset interior states (for housing/apartment scripts)
        TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
        TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)
        -- Open clothing menu for new character if available
        if GetResourceState('qb-clothes') == 'started' then
            TriggerEvent('qb-clothes:client:CreateFirstCharacter')
        elseif GetResourceState('illenium-appearance') == 'started' then
            TriggerEvent('illenium-appearance:client:createCharacter')
        end
    end)
end

-- Spawn the player at their last known position (for existing characters)
local function spawnLastLocation()
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end
    local pos = QBX.PlayerData.position or {}
    local spawnCoords
    if pos.x and pos.y and pos.z then
        spawnCoords = vector4(pos.x, pos.y, pos.z, pos.w or 0.0)
    else
        -- Fallback to default if no last position
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
    end)
end

-- Open character creation input dialog and handle creation
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
    if not input then
        return false -- cancelled
    end
    local fname, lname = input[1], input[2]
    local genderVal    = tonumber(input[3]) or 0
    local birthdate    = input[4]
    local bloodType    = input[5]
    -- Basic validation (ensure not empty)
    if fname == '' or lname == '' or birthdate == '' or bloodType == nil then
        return false
    end
    -- Create character via server callback
    local newId = lib.callback.await('radium-core:server:createCharacter', false, {
        firstname = fname,
        lastname  = lname,
        gender    = genderVal,
        birthdate = birthdate,
        blood     = bloodType,
        cid       = slot
    })
    if not newId then
        return false -- creation failed (e.g., slot limit reached)
    end
    -- Spawn the new character
    spawnDefault()
    return true
end

-- Open the character selection menu
local function openCharacterSelection()
    -- Get characters and slot count from server
    local characters, maxSlots = lib.callback.await('radium-core:server:getCharacters', false)
    characters = characters or {}
    maxSlots = tonumber(maxSlots) or (Config.DefaultNumberOfCharacters or 1)
    -- Prepare player ped for selection (freeze and hide it off-screen)
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    SetEntityCoords(ped, 0.0, 0.0, -100.0, false, false, false, false)
    SetEntityVisible(ped, false, false)
    DisplayRadar(false)
    -- Start solo session so the player is isolated during selection
    NetworkStartSoloTutorialSession()
    while not NetworkIsInTutorialSession() do Wait(0) end
    -- Build context menu options for each character slot
    local options = {}
    for i = 1, maxSlots do
        local char = nil
        for _, v in ipairs(characters) do
            if v.cid == i then char = v; break end
        end
        if char then
            local info = char.charinfo or {}
            local name = (info.firstname and info.lastname) and (info.firstname .. ' ' .. info.lastname) or char.name or ('Character '..i)
            local genderLabel = (char.gender == 0) and 'Male' or 'Female'
            local dob = char.birthdate or info.birthdate or 'Unknown'
            local blood = char.blood or info.blood or 'N/A'
            local csn = char.csn or (info.csn or char.citizenid)
            -- Define sub-menu for this character (Play/Delete)
            local subMenuId = 'radium_char_opts_'..i
            lib.registerContext({
                id = subMenuId,
                title = name..' - Options',
                menu = 'radium_characters',
                canClose = false,
                options = {
                    {
                        title = 'Play',
                        icon = 'play',
                        description = 'Select this character',
                        onSelect = function()
                            DoScreenFadeOut(10)
                            local ok = lib.callback.await('radium-core:server:loadCharacter', false, char.citizenid)
                            if ok then
                                spawnLastLocation()
                            else
                                lib.showContext('radium_characters') -- if load failed, return to menu
                            end
                        end
                    },
                    Config.EnableDeleteCharacter and {
                        title = 'Delete',
                        icon = 'trash',
                        description = 'Delete this character',
                        onSelect = function()
                            if confirmDelete(name) then
                                TriggerServerEvent('radium-core:server:deleteCharacter', char.citizenid)
                                Wait(500) -- small delay for deletion
                                openCharacterSelection() -- refresh the selection menu
                            else
                                lib.showContext(subMenuId) -- return to options if cancelled
                            end
                        end
                    } or nil
                }
            })
            -- Main menu entry for this character
            options[#options+1] = {
                title = string.format("%s [%s]", name, csn),
                description = string.format("DOB: %s | Gender: %s | Blood: %s", dob, genderLabel, blood),
                icon = 'user',
                menu = subMenuId,
                canClose = false,
                onSelect = function()
                    lib.showContext(subMenuId)
                end
            }
        else
            -- Empty slot
            options[#options+1] = {
                title = 'Empty Slot '..i,
                description = 'Create a new character',
                icon = 'plus',
                onSelect = function()
                    local created = openCreateCharacter(i)
                    if not created then
                        lib.showContext('radium_characters') -- reopen menu if creation canceled
                    end
                end
            }
        end
    end
    -- Register and open the main character selection context menu
    lib.registerContext({
        id = 'radium_characters',
        title = 'Character Selection',
        options = options,
        canClose = false
    })
    lib.showContext('radium_characters')
end

-- If you have a logout feature, you can listen for an event to reopen selection:
RegisterNetEvent('radium-core:client:openSelection', function()
    openCharacterSelection()
end)

-- Automatically open character selection when the player joins
CreateThread(function()
    -- Disable auto-spawn from spawnmanager
    pcall(function() exports.spawnmanager:setAutoSpawn(false) end)
    -- Wait for session start, then open menu
    while not NetworkIsSessionStarted() do Wait(0) end
    Wait(250)
    openCharacterSelection()
end)

