Config = {}

-- Radium-Core Configuration (relevant to multicharacter)
Config.useExternalCharacters = false       -- Disable external character system (use Radium-Core's internal multichar)
Config.EnableDeleteCharacter = true        -- Allow players to delete characters
Config.DefaultNumberOfCharacters = 3       -- Default number of character slots per player
Config.PlayersNumberOfCharacters = {       -- Optional: custom max characters per specific license
    -- ['license:xxxxxxxxxxxxxxxx'] = 5,
}
Config.SpawnLocation = vector4(-1035.71, -2731.87, 13.0, 0.0)  -- Default spawn coords (x, y, z, heading) for new characters
