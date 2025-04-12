exports('GetCharacters', function(source)
    local identifier = GetPlayerIdentifierByType(source, "license")
    if not identifier then return {} end
    return MySQL.query.await('SELECT * FROM characters WHERE identifier = ?', { identifier }) or {}
end)

exports('CreateCharacter', function(source, data)
    local identifier = GetPlayerIdentifierByType(source, "license")
    if not identifier then return end

    local csn = GenerateCSN()
    local blood = GenerateBloodType()
    local spawn = Config.SpawnLocations[1].coords

    MySQL.insert.await('INSERT INTO characters (csn, identifier, slot, name, gender, dob, blood_type, job, job_grade, bank, last_location) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        csn, identifier, data.slot, data.name, data.gender, data.dob, blood,
        'unemployed', 0, 5000, json.encode(spawn)
    })

    TriggerEvent('radium-logs:characterCreated', source, csn)
end)

exports('DeleteCharacter', function(source, csn)
    if not csn then return end
    MySQL.execute.await('DELETE FROM characters WHERE csn = ?', { csn })
    TriggerEvent('radium-logs:characterDeleted', source, csn)
end)

exports('LoadCharacter', function(source, csn)
    local char = MySQL.query.await('SELECT * FROM characters WHERE csn = ?', { csn })
    if char and char[1] then
        local data = char[1]
        TriggerClientEvent('radium-core:spawnCharacter', source, {
            name = data.name,
            gender = data.gender,
            dob = data.dob,
            job = data.job,
            job_grade = data.job_grade,
            csn = data.csn,
            bank = data.bank,
            spawn = json.decode(data.last_location)
        })
    end
end)