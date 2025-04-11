Radium = Radium or {}
Radium.Players = Radium.Players or {}

-- Load a player from DB or use default values
function Radium.LoadPlayer(src, identifier)
    if not src or not identifier then return end

    exports.oxmysql:query('SELECT * FROM players WHERE identifier = ?', { identifier }, function(result)
        local data = result[1]

        Radium.Players[src] = {
            id = identifier,
            job = data and data.job or "unemployed",
            job_grade = data and data.job_grade or 0,
            money = {
                cash = data and data.cash or 500,
                bank = data and data.bank or 1000
            },
            coords = vector3(0, 0, 0) -- Future: load coords here
        }

        print(("[Radium-Core] Loaded player %s (%s) from DB"):format(src, identifier))
        TriggerEvent('radium:onPlayerCached', src, Radium.Players[src])
    end)
end

-- Save player data on disconnect
function Radium.UnloadPlayer(src)
    local p = Radium.Players[src]
    if not p then return end

    exports.oxmysql:update([[
        INSERT INTO players (identifier, job, job_grade, cash, bank)
        VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            job = VALUES(job),
            job_grade = VALUES(job_grade),
            cash = VALUES(cash),
            bank = VALUES(bank)
    ]], {
        p.id, p.job, p.job_grade, p.money.cash, p.money.bank
    })

    print(("[Radium-Core] Unloaded and saved player %s"):format(src))
    Radium.Players[src] = nil
end

-- Get cache
function Radium.GetPlayer(src)
    return Radium.Players[src]
end
