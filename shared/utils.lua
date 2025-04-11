Radium = Radium or {}

function Radium.GetIdentifier(source)
    if not source or tonumber(source) == nil then return nil end

    local idTypes = { "discord", "license", "steam" }
    local identifiers = GetPlayerIdentifiers(source)

    for _, idType in pairs(idTypes) do
        for _, id in pairs(identifiers) do
            if id:find(idType .. ":") then
                return id, idType -- return both ID and type
            end
        end
    end

    return nil
end

function Radium.Log(level, msg)
    local prefix = "[Radium]"
    print(string.format("^%s%s^7 %s", level == "error" and "1" or level == "warn" and "3" or "2", prefix, msg))
end

function Radium.TableHasValue(tbl, val)
    for _, v in pairs(tbl) do
        if v == val then return true end
    end
    return false
end

function Radium.Round(val, decimal)
    local d = 10 ^ (decimal or 0)
    return math.floor(val * d + 0.5) / d
end

exports('GetIdentifier', function(src)
    return Radium.GetIdentifier(src)
end)

exports('getSharedObject', function()
    return Radium
end)

