print("[Radium-Core] Loaded: multicharacter.lua")

if Config.useExternalCharacters then
    return -- Disable this module if using an external multicharacter system
end

local function getPlayerLicense(src)
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if string.find(id, "license:") then
            return id
        end
    end
    return nil
end

-- Helper: Load character data from the database for a given citizenid
local function loadCharacterData(src, citizenid)
    local result = MySQL.single.await("SELECT * FROM players WHERE citizenid = ?", { citizenid })
    if not result then return nil end
    -- Verify character belongs to this player's license
    local license = getPlayerLicense(src)
    if result.license ~= license then return nil end
    -- Decode JSON fields
    local charinfo = result.charinfo and json.decode(result.charinfo) or {}
    local money    = result.money and json.decode(result.money) or { cash = 0, bank = 0 }
    local job      = result.job and json.decode(result.job) or { name = "unemployed", label = "Unemployed", grade = 0 }
    local gang     = result.gang and json.decode(result.gang) or {}
    local position = result.position and json.decode(result.position) or nil
    local metadata = result.metadata and json.decode(result.metadata) or {}
    -- Construct player data table
    local playerData = {
        source    = src,
        citizenid = result.citizenid,
        cid       = result.cid,
        license   = result.license,
        name      = result.name,
        charinfo  = charinfo,
        money     = money,
        job       = job,
        gang      = gang,
        position  = position,
        metadata  = metadata,
        phone_number = result.phone_number or nil
    }
    return playerData
end

-- Fetch all characters for a player (callback)
lib.callback.register('radium-core:server:getCharacters', function(source)
    local src = source
    local license = getPlayerLicense(src)
    if not license then return {}, 0 end
    -- Determine max slots for this player
    local maxSlots = Config.DefaultNumberOfCharacters or 1
    if Config.PlayersNumberOfCharacters and Config.PlayersNumberOfCharacters[license] then
        maxSlots = Config.PlayersNumberOfCharacters[license]
    end
    -- Query characters from DB
    local rows = MySQL.query.await("SELECT citizenid, cid, name, charinfo FROM players WHERE license = ? ORDER BY cid ASC", { license }) or {}
    local characters = {}
    for _, row in ipairs(rows) do
        local info = type(row.charinfo) == "string" and json.decode(row.charinfo) or row.charinfo or {}
        -- If `gender`, `birthdate`, or `blood` are stored in charinfo (as in our creation logic), include them for display
        if info.gender ~= nil then row.gender = info.gender end
        if info.birthdate then row.birthdate = info.birthdate end
        if info.blood then row.blood = info.blood end
        if info.csn then row.csn = info.csn end
        row.charinfo = info
        characters[#characters+1] = row
    end
    return characters, maxSlots
end)

-- Create a new character (callback)
lib.callback.register('radium-core:server:createCharacter', function(source, data)
    local src = source
    local license = getPlayerLicense(src)
    if not license or not data then return nil end
    -- Validate required fields
    if not data.firstname or not data.lastname or not data.birthdate or data.gender == nil or not data.blood then
        return nil 
    end
    -- Check slot availability
    local maxSlots = Config.DefaultNumberOfCharacters or 1
    if Config.PlayersNumberOfCharacters and Config.PlayersNumberOfCharacters[license] then
        maxSlots = Config.PlayersNumberOfCharacters[license]
    end
    local charCount = MySQL.scalar.await("SELECT COUNT(*) FROM players WHERE license = ?", { license }) or 0
    if charCount >= maxSlots then 
        return nil 
    end
    -- Determine new character slot (cid)
    local newCid = tonumber(data.cid) or (charCount + 1)
    if MySQL.scalar.await("SELECT 1 FROM players WHERE license = ? AND cid = ?", { license, newCid }) then
        return nil -- slot already in use (shouldn't happen if UI is correct)
    end
    -- Generate unique citizenid
    local function generateCitizenId()
        local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        local id = ""
        for _ = 1, 8 do 
            local rand = math.random(1, #chars)
            id = id .. string.sub(chars, rand, rand)
        end
        return id
    end
    local citizenid = generateCitizenId()
    while MySQL.scalar.await("SELECT 1 FROM players WHERE citizenid = ?", { citizenid }) do
        citizenid = generateCitizenId()
    end
    -- Generate unique CSN (6-digit identifier for character)
    local csn = tostring(math.random(100000, 999999))
    local attempt = 0
    while MySQL.scalar.await("SELECT 1 FROM players WHERE JSON_EXTRACT(charinfo, '$.csn') = ?", { csn }) do
        csn = tostring(math.random(100000, 999999))
        attempt = attempt + 1
        if attempt > 10 then break end
    end
    -- Prepare initial data
    local fullName = data.firstname .. " " .. data.lastname
    local charinfo = {
        firstname = data.firstname,
        lastname  = data.lastname,
        birthdate = data.birthdate,
        gender    = tonumber(data.gender) or 0,   -- 0 = male, 1 = female
        blood     = data.blood,
        csn       = csn
    }
    local job   = { name = "unemployed", label = "Unemployed", grade = 0 }
    local gang  = {}
    local money = { cash = 0, bank = 5000 }
    local pos   = {}        -- no last position yet
    local meta  = {}
    -- Insert into database
    MySQL.insert.await("INSERT INTO players (citizenid, cid, license, name, money, charinfo, job, gang, position, metadata) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", {
        citizenid,
        newCid,
        license,
        fullName,
        json.encode(money),
        json.encode(charinfo),
        json.encode(job),
        json.encode(gang),
        json.encode(pos),
        json.encode(meta)
    })
    -- Load and send the new character data to client
    local playerData = loadCharacterData(src, citizenid)
    if playerData then
        -- (If Radium-Core tracks online players, you could add playerData to that list here)
        TriggerClientEvent('radium-core:client:setPlayerData', src, playerData)
        return playerData.citizenid  -- return the new character's ID
    end
    return nil
end)

-- Load an existing character (callback)
lib.callback.register('radium-core:server:loadCharacter', function(source, citizenid)
    local src = source
    local playerData = loadCharacterData(src, citizenid)
    if playerData then
        -- (If core maintains a Players list, update it here, e.g. RadiumCore.Players[src] = playerData)
        TriggerClientEvent('radium-core:client:setPlayerData', src, playerData)
        return true
    end
    return false
end)

-- Delete a character (event)
RegisterNetEvent('radium-core:server:deleteCharacter', function(citizenid)
    local src = source
    if not Config.EnableDeleteCharacter then return end
    local license = getPlayerLicense(src)
    if not license or not citizenid then return end
    -- Verify ownership
    local owner = MySQL.scalar.await("SELECT license FROM players WHERE citizenid = ?", { citizenid })
    if owner ~= license then return end
    -- Delete from main players table
    MySQL.query.await("DELETE FROM players WHERE citizenid = ?", { citizenid })
    -- Delete from related tables (if they exist)
    local relatedTables = {
        'player_vehicles', 'player_houses', 'player_outfits', 'player_contacts',
        'player_mails', 'phone_messages', 'phone_invoices', 'crypto_transactions', 'bank_accounts'
    }
    for _, tableName in ipairs(relatedTables) do
        MySQL.query.await(string.format("DELETE FROM `%s` WHERE citizenid = ?", tableName), { citizenid })
    end
    -- (Optional: send a notification to the player about deletion success)
end)




