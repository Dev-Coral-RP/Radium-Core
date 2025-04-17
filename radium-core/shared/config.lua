Config = {}

-- Radium-Core multicharacter system settings
Config.useExternalCharacters = false       -- Disable external character system (use Radium-Core's internal multichar)
Config.EnableDeleteCharacter = true        -- Allow players to delete characters
Config.DefaultNumberOfCharacters = 3       -- Default number of character slots per player
Config.PlayersNumberOfCharacters = {       -- Optional: custom max characters per specific license
    -- ['license:xxxxxxxxxxxxxxxx'] = 5,
}
Config.SpawnLocation = vector4(-1035.71, -2731.87, 13.0, 0.0)  -- Default spawn coords (x, y, z, heading) for new characters


 {
    { type = 'clothing', coords = vector3(72.3, -1399.1, 29.4), blip = { sprite = 73, color = 7, text = 'Clothing Store' } },
    { type = 'tattoo',   coords = vector3(1322.6, -1651.9, 51.2), blip = { sprite = 75, color = 1, text = 'Tattoo Parlor' } },
    { type = 'barber',   coords = vector3(-814.3, -183.8, 37.6), blip = { sprite = 71, color = 4, text = 'Barber Shop' } },
    { type = 'surgeon',  coords = vector3(-704.1, -153.9, 37.4), blip = { sprite = 102, color = 8, text = 'Plastic Surgeon' } },
  }
  
  Config.Key = 'E'
