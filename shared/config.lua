Radium = Radium or {}

Radium.Config = {
    FrameworkName = "Radium",
    Debug = true,
    DefaultSpawn = vec3(0.0, 0.0, 0.0)
}

-- Radium Core Configuration (shared/config.lua)
Radium.Config.EnableMulticharacter = true     -- Master toggle for multichar system
Radium.Config.MaxCharacters = 3              -- Number of character slots available
Radium.Config.EnableDeleteCharacter = true   -- Allow players to delete characters
Radium.Config.SpawnLocations = {
    {name = "Legion Square", coords = vec3(215.76, -923.85, 30.69), heading = 0.0},
    {name = "Sandy Shores", coords = vec3(1737.56, 3708.21, 34.14), heading = 0.0}
    -- You can add more predefined spawn locations here.
}
-- (Last location spawn is always available if a character has a saved last position.)


Radium.Config.StartingMoney = {
    cash = 500,         -- Given as item in future
    bank = 1500,
    dirty = 0,
    crypto = 0
}

Radium.Config.Health = {
    regenEnabled = false,       -- Disable native regen
    downedThreshold = 100,      -- Below this, trigger downed state
    debug = false               -- Toggle health logs
}

Radium.Config.Jobs = {
    ["unemployed"] = {
        label = "Unemployed",
        grades = {
            [0] = { name = "Unemployed", pay = 100 }
        }
    },
    ["police"] = {
        label = "Police",
        grades = {
            [0] = { label = "Cadet", pay = 400 },
            [1] = { label = "Officer", pay = 600 },
            [2] = { label = "Sergeant", pay = 800 },
            [3] = { label = "Chief", pay = 1000, isBoss = true }
        }
    },
    ["mechanic"] = {
        label = "Mechanic",
        grades = {
            [0] = { label = "Junior", pay = 300 },
            [1] = { label = "Senior", pay = 500, isBoss = true }
        }
    }
}
