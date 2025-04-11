RegisterCommand('givecash', function(src, args)
    local targetId = tonumber(args[1])
    local amount = tonumber(args[2])

    if not targetId or not amount then
        TriggerClientEvent('chat:addMessage', src, {
            args = { '^1Usage:', '/givecash [targetId] [amount]' }
        })
        return
    end

    local success = Radium.Money.Remove(src, "cash", amount, "give to player")

    if success then
        Radium.Money.Add(targetId, "cash", amount, "received from another player")

        TriggerClientEvent('chat:addMessage', src, {
            args = { '^2Success:', 'You gave $' .. amount .. ' to player ' .. targetId }
        })

        TriggerClientEvent('chat:addMessage', targetId, {
            args = { '^2You received $' .. amount .. ' from player ' .. src }
        })
    else
        TriggerClientEvent('chat:addMessage', src, {
            args = { '^1Error:', 'You don’t have enough cash.' }
        })
    end
end, false)


-- /checkcash - shows your current balance
RegisterCommand('checkcash', function(src)
    local cash = Radium.Money.Get(src, "cash")
    local bank = Radium.Money.Get(src, "bank")

    TriggerClientEvent('chat:addMessage', src, {
        args = { "^2Balance:", "Cash: $" .. cash .. ", Bank: $" .. bank }
    })
end, false)

-- /setcash [id] [amount] [cash|bank] - admin-only
RegisterCommand('setcash', function(src, args)
    local target = tonumber(args[1])
    local amount = tonumber(args[2])
    local account = tostring(args[3] or "cash")

    if not target or not amount or (account ~= "cash" and account ~= "bank") then
        TriggerClientEvent('chat:addMessage', src, {
            args = { "^1Usage:", "/setcash [targetId] [amount] [cash|bank]" }
        })
        return
    end

    local license = Radium.Players[src] and Radium.Players[src].license or nil
    if not Radium.HasPermission or not Radium.HasPermission(license, "admin") then
        TriggerClientEvent('chat:addMessage', src, {
            args = { "^1Error:", "You do not have permission to use this command." }
        })
        return
    end

    Radium.Money.Set(target, account, amount, "admin set")
    TriggerClientEvent('chat:addMessage', src, {
        args = { "^2Success:", "Set $" .. amount .. " " .. account .. " for player " .. target }
    })
end, false)

