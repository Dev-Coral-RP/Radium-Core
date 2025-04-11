function Radium.LogToDiscord(type, message)
    local color = type == "create" and 3066993 or type == "delete" and 15158332 or 3447003
    local payload = {
        username = "Radium Logs",
        embeds = {{
            title = "**" .. type:upper() .. "**",
            description = message,
            color = color
        }}
    }

    PerformHttpRequest(Radium.Config.MultiCharacter.Webhook, function() end, "POST", json.encode(payload), {
        ['Content-Type'] = 'application/json'
    })
end
