Radium = Radium or {}
Radium.Characters = Radium.Characters or {}

-- Character loader function (MUST be here so it's available immediately)
Radium.Characters.GetAll = function(identifier, cb)
    exports.oxmysql:query('SELECT * FROM characters WHERE identifier = ?', { identifier }, function(result)
        local slots = {}
        for _, row in ipairs(result or {}) do
            slots[row.slot or 1] = row
        end
        cb(slots)
    end)
end

-- Player connects
AddEventHandler('playerConnecting', function(name, setKick, deferrals)
    local src = source
    deferrals.defer()
    Wait(100)

    local identifiers
    local attempts = 0
    repeat
        identifiers = GetPlayerIdentifiers(src)
        attempts = attempts + 1
        Wait(100)
    until #identifiers > 0 or attempts >= 10

    print("[Radium Debug] Identifiers for source:", src)
    if #identifiers == 0 then
        print("[Radium Debug] No identifiers found for player", src)
        deferrals.done("We couldn't verify your identity. Please restart FiveM.")
        return
    end

    for i, id in ipairs(identifiers) do
        print(string.format("[Radium Debug] Identifier %d: %s", i, id))
    end

    local identifier, idType = Radium.GetIdentifier(src)
    if not identifier then
        deferrals.done("You must have Steam or Discord open to play.")
        return
    end

    deferrals.update("Loading Radium Core...")
    Wait(200)

    Radium.Log("info", ("Player %s connected using %s"):format(src, idType))
    TriggerEvent('radium:playerLoaded', src, identifier)
    deferrals.done()
end)

AddEventHandler('radium:playerLoaded', function(src, identifier)
    if Radium.Config.EnableMulticharacter then
        -- Fetch all character slots for this player and open selection UI
        Radium.Characters.GetAll(identifier, function(characters)
            TriggerClientEvent('radium:showCharacterMenu', src, characters)
        end)
    else
        -- Single-character fallback (if multicharacter is disabled)
        Radium.LoadPlayer(src, identifier)  -- normal single-character loading
        TriggerClientEvent('radium:spawn', src) 
    end
end)

Radium = Radium or {}
Radium.Banking = {}

-- Default starting money config
Radium.Config.StartingMoney = {
    bank = 1000,
    crypto = 0,
    dirty = 0
}

-- Create a bank account using CSN as the unique bank ID
function Radium.Banking.CreateAccount(csn, cb)
    local bankID = csn -- We use CSN as bank ID

    exports.oxmysql:insert([[
        INSERT INTO bank_accounts (bank_id, balance, crypto, dirty_money)
        VALUES (?, ?, ?, ?)
    ]], {
        bankID,
        Radium.Config.StartingMoney.bank,
        Radium.Config.StartingMoney.crypto,
        Radium.Config.StartingMoney.dirty
    }, function(success)
        if success then
            Radium.Log("info", ("Bank account created for CSN: %s"):format(csn))
        else
            Radium.Log("error", ("Failed to create bank account for CSN: %s"):format(csn))
        end
        if cb then cb(success) end
    end)
end

-- Get balance
function Radium.Banking.GetBalance(csn, cb)
    exports.oxmysql:query('SELECT balance, crypto, dirty_money FROM bank_accounts WHERE bank_id = ?', { csn }, function(result)
        if result and result[1] then
            cb(result[1])
        else
            cb({ balance = 0, crypto = 0, dirty_money = 0 })
        end
    end)
end

-- Add money
function Radium.Banking.AddMoney(csn, type, amount)
    local col = type == "crypto" and "crypto" or type == "dirty" and "dirty_money" or "balance"
    exports.oxmysql:update(('UPDATE bank_accounts SET %s = %s + ? WHERE bank_id = ?'):format(col, col), {
        amount, csn
    })
end

-- Remove money
function Radium.Banking.RemoveMoney(csn, type, amount)
    local col = type == "crypto" and "crypto" or type == "dirty" and "dirty_money" or "balance"
    exports.oxmysql:update(('UPDATE bank_accounts SET %s = GREATEST(%s - ?, 0) WHERE bank_id = ?'):format(col, col), {
        amount, csn
    })
end

-- Delete bank account (called when character is deleted)
function Radium.Banking.DeleteAccount(csn)
    exports.oxmysql:update('DELETE FROM bank_accounts WHERE bank_id = ?', { csn })
end

-- Exported for use by external scripts
exports('GetBalance', Radium.Banking.GetBalance)
exports('AddMoney', Radium.Banking.AddMoney)
exports('RemoveMoney', Radium.Banking.RemoveMoney)


Radium = Radium or {}
Radium.Health = {}

-- Save health on disconnect (optional for future DB)
AddEventHandler("playerDropped", function()
    local src = source
    local ped = GetPlayerPed(src)
    if DoesEntityExist(ped) then
        local health = GetEntityHealth(ped)
        Radium.Log("info", ("Saved health for %s: %s"):format(src, health))
        -- Save to DB here if you add health persistence
    end
end)

-- Logging if player goes down
RegisterNetEvent("radium:logHealthDown", function(health)
    local src = source
    Radium.Log("warn", ("Player %s is downed at %s health"):format(src, health))
end)

-- Exported functions
exports("GetHealth", function(src)
    local ped = GetPlayerPed(src)
    if DoesEntityExist(ped) then
        return GetEntityHealth(ped)
    end
    return 0
end)

exports("SetHealth", function(src, amount)
    local ped = GetPlayerPed(src)
    if DoesEntityExist(ped) then
        SetEntityHealth(ped, amount)
        Radium.Log("info", ("Health for %s set to %s"):format(src, amount))
    end
end)

exports("IsDowned", function(src)
    local ped = GetPlayerPed(src)
    return GetEntityHealth(ped) < Radium.Config.Health.downedThreshold
end)



Radium = Radium or {}

-- Set a job (with grade validation)
function Radium.SetJob(src, job, grade)
    local p = Radium.GetPlayer(src)
    if not p then return false end

    local jobDef = Radium.Config.Jobs[job]
    if not jobDef then return false end

    grade = tonumber(grade) or 0
    if not jobDef.grades[grade] then return false end

    p.job = job
    p.job_grade = grade

    Radium.Log("info", ("Set job for %s to %s (%s)"):format(src, job, grade))
    return true
end

function Radium.GetJobInfo(src)
    local p = Radium.GetPlayer(src)
    if not p then return nil end

    local jobData = Radium.Config.Jobs[p.job]
    if not jobData then return nil end

    return {
        name = p.job,
        grade = p.job_grade,
        label = jobData.label,
        grade_name = jobData.grades[p.job_grade].name,
        pay = jobData.grades[p.job_grade].pay
    }
end

function Radium.Promote(src)
    local p = Radium.GetPlayer(src)
    if not p then return false end

    local job = p.job
    local grade = p.job_grade + 1

    if Radium.Config.Jobs[job] and Radium.Config.Jobs[job].grades[grade] then
        p.job_grade = grade
        Radium.Log("info", ("Promoted %s to grade %s (%s)"):format(src, grade, Radium.Config.Jobs[job].grades[grade].name))
        return true
    end
    return false
end

function Radium.Demote(src)
    local p = Radium.GetPlayer(src)
    if not p then return false end

    local grade = p.job_grade - 1
    if grade >= 0 then
        p.job_grade = grade
        Radium.Log("info", ("Demoted %s to grade %s"):format(src, grade))
        return true
    end
    return false
end

function Radium.Fire(src)
    return Radium.SetJob(src, "unemployed", 0)
end


RegisterCommand("setjob", function(src, args)
    local target = tonumber(args[1])
    local job = args[2]
    local grade = tonumber(args[3]) or 0

    if not Radium.IsJobBoss(src) then
        TriggerClientEvent('chat:addMessage', src, {
            args = { "^1Error:", "You are not a boss." }
        })
        return
    end

    if not Radium.Players[target] then return end
    if not Radium.Config.Jobs[job] then return end
    if not Radium.Config.Jobs[job].grades[grade] then return end

    Radium.Players[target].job = job
    Radium.Players[target].job_grade = grade

    -- Save to DB
    exports.oxmysql:update("UPDATE characters SET job = ?, job_grade = ? WHERE identifier = ?", {
        job, grade, Radium.Players[target].license
    })

    TriggerClientEvent('chat:addMessage', target, {
        args = { "^2Hired as " .. Radium.Config.Jobs[job].grades[grade].label }
    })
end, false)


RegisterCommand("job", function(src, args)
    local player = Radium.Players[src]
    if not player then return end

    local jobName = player.job
    local grade = player.job_grade

    local jobConfig = Radium.Config.Jobs[jobName]
    local jobLabel = jobConfig and jobConfig.label or "Unknown"
    local gradeLabel = jobConfig and jobConfig.grades[grade] and jobConfig.grades[grade].label or "Unknown"

    TriggerClientEvent("radium:notifyJob", src, "radium-core", { message = ("Job: %s (%s)"):format(jobLabel, gradeLabel) })
end)



Radium = Radium or {}
Radium.Money = Radium.Money or {}
Radium.Players = Radium.Players or {}

-- Initialize player money data on load
AddEventHandler('radium:playerLoaded', function(src, license)
    Radium.Players[src] = {
        license = license,
        money = {
            cash = 500, -- default values (or load from DB later)
            bank = 1000
        }
    }

    Radium.Log("info", ("Player %s connected with license: %s"):format(src, license))

    -- Optional: Add admin check here
    if Radium.HasPermission and Radium.HasPermission(license, "admin") then
        Radium.Log("info", "Player is an admin.")
    end
end)

-- Clean up when player disconnects
AddEventHandler('playerDropped', function()
    Radium.Players[source] = nil
end)

-- Add money securely
function Radium.Money.Add(src, account, amount, reason)
    if not Radium.Players[src] or not Radium.Players[src].money[account] then return end
    amount = tonumber(amount)
    if amount <= 0 then return end

    Radium.Players[src].money[account] = Radium.Players[src].money[account] + amount
    Radium.Money.Notify(src, account, amount, "add", reason)
end

-- Remove money securely
function Radium.Money.Remove(src, account, amount, reason)
    if not Radium.Players[src] or not Radium.Players[src].money[account] then return end
    amount = tonumber(amount)
    if amount <= 0 then return end

    if Radium.Players[src].money[account] < amount then
        Radium.Log("warn", ("Player %s tried to remove more than they have in %s"):format(src, account))
        return false
    end

    Radium.Players[src].money[account] = Radium.Players[src].money[account] - amount
    Radium.Money.Notify(src, account, amount, "remove", reason)
    return true
end

-- Get current balance
function Radium.Money.Get(src, account)
    if not Radium.Players[src] then return 0 end
    return Radium.Players[src].money[account] or 0
end

-- Set money directly (e.g., for admin, dev tools)
function Radium.Money.Set(src, account, amount, reason)
    if not Radium.Players[src] then return end
    Radium.Players[src].money[account] = tonumber(amount)
    Radium.Money.Notify(src, account, amount, "set", reason)
end

-- Notify (simple chat-based, upgrade to NUI later)
function Radium.Money.Notify(src, account, amount, action, reason)
    local msg = ("💰 %s %s $%s [%s]"):format(
        account,
        action == "add" and "received" or action == "remove" and "lost" or "set to",
        amount,
        reason or "unknown"
    )
    TriggerClientEvent('chat:addMessage', src, {
        args = { "[Money]", msg }
    })
end


CreateThread(function()
    while true do
        Wait(1000 * 60 * 30) -- Every 30 mins

        for src, data in pairs(Radium.Players) do
            local job = data.job
            local grade = data.job_grade

            local def = Radium.Config.Jobs[job]
            if def and def.grades[grade] then
                local pay = def.grades[grade].pay or 0
                data.money.bank = data.money.bank + pay

                TriggerClientEvent('chat:addMessage', src, {
                    args = { "^2Paycheck:", ("You received $%s into your bank account."):format(pay) }
                })

                Radium.Log("info", ("Paid %s $%s (job: %s)"):format(src, pay, job))
            end
        end
    end
end)



-- Exports
exports('GetJob', Radium.GetJob)
exports('SetJob', Radium.SetJob)
exports('GetMoney', Radium.GetMoney)
exports('SetMoney', Radium.SetMoney)
exports('AddMoney', Radium.AddMoney)
exports('RemoveMoney', Radium.RemoveMoney)
