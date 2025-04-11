Radium = Radium or {}

local MySQL = exports.oxmysql

Radium.DB = {}

function Radium.DB.Fetch(query, params, cb)
    MySQL.query(query, params or {}, function(result)
        if cb then cb(result) end
    end)
end

function Radium.DB.Execute(query, params, cb)
    MySQL.update(query, params or {}, function(affected)
        if cb then cb(affected) end
    end)
end
