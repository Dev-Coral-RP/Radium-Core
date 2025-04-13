local function generateCSN()
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local nums = '0123456789'
    local result = ''

    for i = 1, 3 do
        local rand = math.random(#chars)
        result = result .. chars:sub(rand, rand)
    end
    for i = 1, 4 do
        local rand = math.random(#nums)
        result = result .. nums:sub(rand, rand)
    end

    return result
end

local function generateBlood()
    local types = { 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-' }
    return types[math.random(1, #types)]
end

---@param source number
---@return string?
local function getIdentifier(source)
    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        if id:sub(1, 7) == "license" then
            return id
        end
    end
    return nil
end

lib.callback.register('radium-multicharacter:getCharacters', function(source)
    local identifier = getIdentifier(source)
    if not identifier then return {} end

    local result = MySQL.query.await('SELECT * FROM characters WHERE identifier = ?', { identifier })
    return result or {}
end)

RegisterServerEvent('radium-multicharacter:createCharacter', function(data)
    local src = source
    local identifier = getIdentifier(src)
    if not identifier then return end

    local existing = MySQL.scalar.await('SELECT COUNT(*) FROM characters WHERE identifier = ?', { identifier })
    if existing >= Config.MaxSlots then
        return -- Optionally notify using ox_lib here
    end

    local csn = generateCSN()
    local blood = generateBlood()

    MySQL.insert.await('INSERT INTO characters (csn, identifier, slot, name, gender, dob, blood_type) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        csn,
        identifier,
        data.slot,
        data.name,
        data.gender,
        data.dob,
        blood
    })

    print(('[Radium-MC] Created character (%s) for ID %s'):format(csn, identifier))
end)

RegisterServerEvent('radium-multicharacter:deleteCharacter', function(slot)
    local src = source
    if not Config.AllowCharacterDelete then return end

    local identifier = getIdentifier(src)
    if not identifier then return end

    MySQL.execute.await('DELETE FROM characters WHERE identifier = ? AND slot = ?', {
        identifier, slot
    })

    print(('[Radium-MC] Deleted character in slot %s for ID %s'):format(slot, identifier))
end)

RegisterServerEvent('radium-multicharacter:selectCharacter', function(slot)
    local src = source
    local identifier = getIdentifier(src)
    if not identifier then return end

    local result = MySQL.query.await('SELECT * FROM characters WHERE identifier = ? AND slot = ?', {
        identifier, slot
    })

    local char = result and result[1]
    if not char then return end

    -- Use ox_lib to spawn after small delay
    Wait(500)
    TriggerClientEvent('radium-multicharacter:spawnCharacter', src, {
        name = char.name,
        dob = char.dob,
        gender = char.gender,
        csn = char.csn,
        job = char.job,
        job_grade = char.job_grade,
        bank = char.bank,
        blood_type = char.blood_type,
        spawn = Config.SpawnLocation
    })

    print(('[Radium-MC] Loaded character %s (Slot %s)'):format(char.name, char.slot))
end)
