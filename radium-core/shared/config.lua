Config = {}

-- Radium-Core Configuration (relevant to multicharacter)
Config.useExternalCharacters = false       -- Disable external character system (use Radium-Core's internal multichar)
Config.EnableDeleteCharacter = true        -- Allow players to delete characters
Config.DefaultNumberOfCharacters = 3       -- Default number of character slots per player
Config.PlayersNumberOfCharacters = {       -- Optional: custom max characters per specific license
    -- ['license:xxxxxxxxxxxxxxxx'] = 5,
}
Config.SpawnLocation = vector4(-1035.71, -2731.87, 13.0, 0.0)  -- Default spawn coords (x, y, z, heading) for new characters


-- Plastic Surgeon settings
Config.PlasticSurgery = {
    Locations = {
        vector4(-39.04, -1388.09, 30.49, 138.0),  -- Example location (Los Santos)
        vector4(1211.52, -475.32, 66.21, 75.0)    -- Another example (County hospital)
    },
    Prices = {
        heritage     = 500,   -- Change heritage (parents)
        faceFeatures = 750,   -- Adjust face shape features
        headOverlays = 500,   -- Facial overlays (blemishes, makeup, etc.)
        facialHair   = 300,   -- Facial hair (beard) change
        hair         = 300,   -- Hairstyle change
        eyeColor     = 200    -- Eye color change
    }
}

-- Clothing Shop settings
Config.ClothingShops = {
    Locations = {
        vector4(425.13, -806.79, 29.49, 90.0),    -- Example clothing store (Downtown)
        vector4(-162.63, -303.42, 39.73, 250.0)   -- Another example (Alta St)
    },
    Prices = {
        mask      = 100,
        top       = 150,    -- Outer shirt / jacket
        undershirt= 50,
        arms      = 0,      -- Arms adjustment (free, included with top)
        pants     = 100,
        shoes     = 100,
        bag       = 100,
        hat       = 75,
        glasses   = 75,
        ears      = 50,     -- Ear accessories
        watch     = 50,
        bracelet  = 50,
        tattoos   = 500     -- Tattoo purchase/removal
    }
}

-- (Optional) Define available tattoos (with collection and overlay names for each gender)
Config.Tattoos = {
    {
        name = "Dragon Back Tattoo",
        part = "Torso",
        collection = "mpbusiness_overlays",      -- Tattoo collection dictionary name
        maleOverlay = "MP_Buis_M_Stomach_000",    -- Overlay name for male
        femaleOverlay = "MP_Buis_F_Stomach_000"   -- Overlay name for female
    },
    {
        name = "Flaming Skull Tattoo",
        part = "Arm",
        collection = "mpchristmas2_overlays",
        maleOverlay = "MP_Xmas2_M_Tat_006", 
        femaleOverlay = "MP_Xmas2_F_Tat_006"
    }
    -- Add more tattoo entries as needed...
}
