local currentAppearance = {}  -- stores the player's current appearance data
Radium = Radium or {}
Radium.PlasticSurgery = Radium.PlasticSurgery or {}


-- Utility: apply the appearance table to the player's ped
local function applyAppearance(appearance)
    local ped = PlayerPedId()
    local model = appearance.model or `mp_m_freemode_01`
    -- If model differs, load and set the model
    if GetEntityModel(ped) ~= GetHashKey(model) then
        RequestModel(model)
        while not HasModelLoaded(model) do Wait(0) end
        SetPlayerModel(PlayerId(), model)
        SetModelAsNoLongerNeeded(model)
        ped = PlayerPedId()  -- update ped after model change
    end

    -- Apply head blend (heritage)
    if appearance.headBlend then
        local hb = appearance.headBlend
        SetPedHeadBlendData(ped, hb.shapeFirst, hb.shapeSecond, hb.shapeThird or 0,
                                   hb.skinFirst,  hb.skinSecond,  hb.skinThird or 0,
                                   hb.shapeMix or 0.5, hb.skinMix or 0.5, hb.thirdMix or 0.0, false)
    end

    -- Apply face features (face shape sliders)
    if appearance.faceFeatures then
        for i, val in pairs(appearance.faceFeatures) do
            SetPedFaceFeature(ped, tonumber(i), val)
        end
    end

    -- Apply head overlays (facial details like hair, blemishes, etc.)
    if appearance.headOverlays then
        for id, overlay in pairs(appearance.headOverlays) do
            local index = overlay.style or 255  -- 255 will remove the overlay
            local opacity = overlay.opacity or 1.0
            SetPedHeadOverlay(ped, tonumber(id), index, opacity)
            -- Apply overlay color if applicable
            if overlay.color ~= nil then
                local colorType = 0
                if id == 1 or id == 2 or id == 10 or id == 4 then 
                    colorType = 1  -- facial hair, eyebrows, chest hair, makeup use colorType 1
                elseif id == 5 or id == 8 then 
                    colorType = 2  -- blush and lipstick use colorType 2
                end
                local color = overlay.color
                local secondColor = overlay.secondColor or color
                SetPedHeadOverlayColor(ped, tonumber(id), colorType, color, secondColor)
            end
        end
    end

    -- Apply eye color
    if appearance.eyeColor then
        SetPedEyeColor(ped, appearance.eyeColor)
    end

    -- Apply hair (component 2) and hair colors
    if appearance.hair then
        SetPedComponentVariation(ped, 2, appearance.hair.style or 0, 0, 0)
        local color1 = appearance.hair.color or 0
        local color2 = appearance.hair.highlight or 0
        SetPedHairColor(ped, color1, color2)
    end

    -- Apply clothing components (props and wearables)
    if appearance.components then
        for compId, compData in pairs(appearance.components) do
            SetPedComponentVariation(ped, tonumber(compId), compData.drawable, compData.texture or 0, 0)
        end
    end
    if appearance.props then
        for propId, propData in pairs(appearance.props) do
            if propData.drawable == -1 then
                ClearPedProp(ped, tonumber(propId))  -- remove prop if drawable == -1
            else
                SetPedPropIndex(ped, tonumber(propId), propData.drawable, propData.texture or 0, true)
            end
        end
    end

    -- Apply tattoos (decorations)
    ClearPedDecorations(ped)  -- clear any existing tattoos before applying
    if appearance.tattoos then
        for _, tat in ipairs(appearance.tattoos) do
            if tat.collection and tat.overlay then
                AddPedDecorationFromHashes(ped, GetHashKey(tat.collection), GetHashKey(tat.overlay))
            end
        end
    end

    -- Store the applied appearance in the currentAppearance table
    currentAppearance = appearance
end

-- When player loads in or character is selected, apply their saved appearance
RegisterNetEvent('Radium:Appearance:Apply', function(appearanceData)
    if type(appearanceData) == "string" then 
        appearanceData = json.decode(appearanceData) or {} 
    end
    if appearanceData.model == nil then
        -- If no appearance data, default to mp_m_freemode_01 with base components
        appearanceData = {
            model = 'mp_m_freemode_01',
            headBlend = { shapeFirst=0, shapeSecond=0, shapeThird=0, skinFirst=0, skinSecond=0, skinThird=0, shapeMix=0.5, skinMix=0.5 },
            faceFeatures = {}, headOverlays = {}, eyeColor = 0,
            hair = { style=0, color=0, highlight=0 },
            components = {
                [3] = { drawable = 15, texture = 0 },    -- arms default
                [4] = { drawable = 0,  texture = 0 },    -- pants
                [6] = { drawable = 0,  texture = 0 },    -- shoes
                [8] = { drawable = 15, texture = 0 },    -- undershirt (invisible)
                [11]= { drawable = 0,  texture = 0 }     -- top
            },
            props = {}, tattoos = {}
        }
    end
    applyAppearance(appearanceData)
end)

-- Helper: open heritage menu (choose parents and mix)
local function openHeritageMenu()
    local ped = PlayerPedId()
    local currentHB = currentAppearance.headBlend or {shapeFirst=0, shapeSecond=0, skinFirst=0, skinSecond=0, shapeMix=0.5, skinMix=0.5}
    -- Prepare list of valid parent face IDs (0-45 typically, where 0-21 mothers, 21-45 fathers in GTA)
    -- We'll allow user to input numeric IDs directly for simplicity
    local input = lib.inputDialog('Choose Heritage', {
        { type = 'number', label = 'Mother ID (0-21)', default = currentHB.shapeFirst or 0, min = 0, max = 21 },
        { type = 'number', label = 'Father ID (0-23)', default = currentHB.shapeSecond or 0, min = 0, max = 23 },
        { type = 'slider', label = 'Shape Mix (Mother←→Father)', default = math.floor((currentHB.shapeMix or 0.5)*100), min = 0, max = 100 },
        { type = 'slider', label = 'Skin Mix (Mother←→Father)',  default = math.floor((currentHB.skinMix or 0.5)*100), min = 0, max = 100 }
    })
    if input then
        local motherId, fatherId = tonumber(input[1]) or 0, tonumber(input[2]) or 0
        local shapeMix = (tonumber(input[3]) or 50) / 100.0
        local skinMix  = (tonumber(input[4]) or 50) / 100.0
        -- Apply to ped
        SetPedHeadBlendData(ped, fatherId, motherId, 0, fatherId, motherId, 0, 1.0 - shapeMix, 1.0 - skinMix, 0.0, false)
        -- Update currentAppearance
        currentAppearance.headBlend = {
            shapeFirst = motherId, shapeSecond = fatherId, shapeThird = 0,
            skinFirst = motherId, skinSecond = fatherId, skinThird = 0,
            shapeMix = shapeMix, skinMix = skinMix, thirdMix = 0.0
        }
    end
end

-- Helper: open face features menu (20 facial feature sliders)
local function openFaceFeaturesMenu()
    local ped = PlayerPedId()
    local features = currentAppearance.faceFeatures or {}
    -- Build slider inputs for each facial feature
    local featureInputs = {}
    local featureNames = {
        [0] = "Nose Width", [1] = "Nose Peak Height", [2] = "Nose Length",
        [3] = "Nose Bridge Depth", [4] = "Nose Tip Height", [5] = "Nose Bridge Shift",
        [6] = "Brow Height", [7] = "Brow Width", [8] = "Cheekbone Height", [9] = "Cheekbone Width",
        [10] = "Cheek Depth", [11] = "Eye Size", [12] = "Lip Thickness",
        [13] = "Jaw Width", [14] = "Jaw Shape", [15] = "Chin Height",
        [16] = "Chin Length", [17] = "Chin Width", [18] = "Chin Position", [19] = "Neck Thickness"
    }
    for i = 0, 19 do
        local currentVal = features[tostring(i)] or features[i] or 0.0
        local percent = math.floor(((currentVal + 1.0) / 2.0) * 100)  -- convert [-1,1] to [0,100]
        table.insert(featureInputs, { type = 'slider', label = featureNames[i] or ("Feature "..i), default = percent, min = 0, max = 100 })
    end
    local input = lib.inputDialog('Face Shape Features', featureInputs)
    if input then
        for i = 0, 19 do
            local percent = tonumber(input[i+1]) or 50
            local val = (percent / 100.0) * 2.0 - 1.0  -- convert back to [-1,1]
            SetPedFaceFeature(ped, i, val)
            features[tostring(i)] = tonumber(string.format("%.2f", val))  -- round to 2 decimals for storage
        end
        currentAppearance.faceFeatures = features
    end
end

-- Helper: open facial overlays category menu (acne, aging, makeup, etc.)
local function openFacialOverlaysMenu()
    -- List each overlay category to customize
    local overlayOptions = {
        { title = "Blemishes", id = 0 },
        { title = "Facial Hair", id = 1 },
        { title = "Eyebrows", id = 2 },
        { title = "Ageing", id = 3 },
        { title = "Makeup", id = 4 },
        { title = "Blush", id = 5 },
        { title = "Complexion", id = 6 },
        { title = "Sun Damage", id = 7 },
        { title = "Lipstick", id = 8 },
        { title = "Moles/Freckles", id = 9 },
        { title = "Chest Hair", id = 10 },
        { title = "Body Blemishes", id = 11 },
        { title = "Body Blemishes 2", id = 12 }
    }
    local submenu = {}
    for _, opt in ipairs(overlayOptions) do
        table.insert(submenu, {
            title = opt.title,
            description = "Customize "..opt.title,
            args = opt.id,
            event = "Radium:Appearance:EditOverlay"  -- will trigger an event to handle input
        })
    end
    lib.registerContext({ id = 'radium:overlayMenu', title = 'Facial Overlays', options = submenu })
    lib.showContext('radium:overlayMenu')
end

-- Event handler: open input to edit a specific overlay category
RegisterNetEvent('Radium:Appearance:EditOverlay', function(overlayID)
    local ped = PlayerPedId()
    overlayID = tonumber(overlayID)
    local currentOv = currentAppearance.headOverlays or {}
    local currentStyle = (currentOv[overlayID] and currentOv[overlayID].style) or 255  -- 255 = none
    local currentOpacity = (currentOv[overlayID] and currentOv[overlayID].opacity) or 1.0
    local hasColor = (overlayID == 1 or overlayID == 2 or overlayID == 10 or overlayID == 4 or overlayID == 5 or overlayID == 8)
    local currentColor = (currentOv[overlayID] and currentOv[overlayID].color) or 0
    local maxIndex = GetNumHeadOverlayValues(overlayID) - 1  -- maximum style index
    if maxIndex < 0 then maxIndex = 0 end  -- safety
    -- Prepare input fields
    local rows = {
        { type = 'number', label = 'Style (0-'..maxIndex..' , -1 None)', default = (currentStyle == 255 and -1 or currentStyle), min = -1, max = maxIndex },
        { type = 'slider', label = 'Opacity (%)', default = math.floor(currentOpacity * 100), min = 0, max = 100 }
    }
    if hasColor then
        local maxColor = GetNumHairColors() - 1  -- hair/makeup colors count (shared palette for hair, eyebrow, beard, makeup)
        if overlayID == 5 or overlayID == 8 then
            -- Blush/Lipstick use makeup palette (colorType 2), but we'll use hair colors count as approximation
            maxColor = GetNumHairColors() - 1  -- (could be different count for makeup, but using hair palette for simplicity)
        end
        table.insert(rows, { type = 'number', label = 'Color (0-'..maxColor..')', default = currentColor, min = 0, max = maxColor })
    end
    local input = lib.inputDialog('Edit '..overlayID..' Overlay', rows)
    if input then
        local style = tonumber(input[1]) or -1
        local opacityPercent = tonumber(input[2]) or 100
        local opacity = opacityPercent / 100.0
        local color = hasColor and tonumber(input[3]) or nil
        -- Apply overlay to ped
        local index = style >= 0 and style or 255  -- convert -1 to 255 for none
        SetPedHeadOverlay(ped, overlayID, index, opacity)
        if hasColor and color ~= nil then
            local colorType = (overlayID == 5 or overlayID == 8) and 2 or 1
            SetPedHeadOverlayColor(ped, overlayID, colorType, color, color)
        end
        -- Update currentAppearance
        currentOv[overlayID] = { style = index, opacity = tonumber(string.format("%.2f", opacity)) }
        if hasColor and color ~= nil then
            currentOv[overlayID].color = color
            currentOv[overlayID].secondColor = color  -- use same color for secondary if applicable
        end
        currentAppearance.headOverlays = currentOv
    end
end)

-- Helper: change eye color
local function changeEyeColor()
    local ped = PlayerPedId()
    local current = currentAppearance.eyeColor or 0
    local input = lib.inputDialog('Eye Color', {
        { type = 'number', label = 'Eye Color ID (0-31)', default = current, min = 0, max = 31 }
    })
    if input then
        local color = tonumber(input[1]) or current
        SetPedEyeColor(ped, color)
        currentAppearance.eyeColor = color
    end
end

-- Helper: open hair style menu
local function openHairMenu()
    local ped = PlayerPedId()
    local modelHash = GetEntityModel(ped)
    local isMale = (modelHash == GetHashKey('mp_m_freemode_01'))
    -- Determine max hair drawables for this ped:
    local maxHair = GetNumberOfPedDrawableVariations(ped, 2) - 1
    if maxHair < 0 then maxHair = 0 end
    local hairData = currentAppearance.hair or { style = 0, color = 0, highlight = 0 }
    local curStyle = hairData.style or 0
    local curColor = hairData.color or 0
    local curHighlight = hairData.highlight or 0
    local maxHairColor = GetNumHairColors() - 1  -- total hair colors
    local input = lib.inputDialog('Hair Style & Color', {
        { type = 'number', label = 'Hair Style (0-'..maxHair..')', default = curStyle, min = 0, max = maxHair },
        { type = 'number', label = 'Hair Color (0-'..maxHairColor..')', default = curColor, min = 0, max = maxHairColor },
        { type = 'number', label = 'Hair Highlight (0-'..maxHairColor..')', default = curHighlight, min = 0, max = maxHairColor }
    })
    if input then
        local style = tonumber(input[1]) or curStyle
        local color = tonumber(input[2]) or curColor
        local highlight = tonumber(input[3]) or curHighlight
        -- Apply to ped
        SetPedComponentVariation(ped, 2, style, 0, 0)
        SetPedHairColor(ped, color, highlight)
        -- Update currentAppearance
        currentAppearance.hair = { style = style, color = color, highlight = highlight }
    end
end

-- Helper: open facial hair (beard) menu
local function openBeardMenu()
    local ped = PlayerPedId()
    local overlayID = 1  -- facial hair overlay
    local currentOv = currentAppearance.headOverlays or {}
    local curStyle = (currentOv[overlayID] and currentOv[overlayID].style) or 255
    if curStyle == 255 then curStyle = -1 end  -- use -1 to represent none in UI
    local curOpacity = (currentOv[overlayID] and currentOv[overlayID].opacity) or 1.0
    local curColor = (currentOv[overlayID] and currentOv[overlayID].color) or 0
    local maxBeard = GetNumHeadOverlayValues(overlayID) - 1
    if maxBeard < 0 then maxBeard = 0 end
    local maxHairColor = GetNumHairColors() - 1
    local input = lib.inputDialog('Facial Hair', {
        { type = 'number', label = 'Beard Style (0-'..maxBeard..', -1 None)', default = curStyle, min = -1, max = maxBeard },
        { type = 'slider', label = 'Beard Opacity (%)', default = math.floor(curOpacity * 100), min = 0, max = 100 },
        { type = 'number', label = 'Beard Color (0-'..maxHairColor..')', default = curColor, min = 0, max = maxHairColor }
    })
    if input then
        local style = tonumber(input[1]) or -1
        local opacity = (tonumber(input[2]) or 100) / 100.0
        local color = tonumber(input[3]) or curColor
        local index = style >= 0 and style or 255
        SetPedHeadOverlay(ped, overlayID, index, opacity)
        SetPedHeadOverlayColor(ped, overlayID, 1, color, color)  -- colorType 1 for facial hair
        currentAppearance.headOverlays = currentAppearance.headOverlays or {}
        currentAppearance.headOverlays[overlayID] = { style = index, opacity = tonumber(string.format("%.2f", opacity)), color = color, secondColor = color }
    end
end

-- Clothing helper: change a component (mask, top, undershirt, arms, pants, shoes, bag)
RegisterNetEvent('Radium:Appearance:ChangeClothing', function(category)
    local ped = PlayerPedId()
    category = tostring(category)
    -- Map category to component ID
    local compMap = {
        mask = 1, top = 11, undershirt = 8, arms = 3,
        pants = 4, shoes = 6, bag = 5
    }
    local compId = compMap[category]
    if not compId then return end
    -- Determine max drawable and current values
    local current = currentAppearance.components and currentAppearance.components[compId] or { drawable = 0, texture = 0 }
    local curDrawable = current.drawable or 0
    local curTexture = current.texture or 0
    local maxDrawable = GetNumberOfPedDrawableVariations(ped, compId) - 1
    if maxDrawable < 0 then maxDrawable = 0 end
    local maxTexture = GetNumberOfPedTextureVariations(ped, compId, curDrawable) - 1
    if maxTexture < 0 then maxTexture = 0 end
    local input = lib.inputDialog('Change '..category, {
        { type = 'number', label = 'Variation (0-'..maxDrawable..')', default = curDrawable, min = 0, max = maxDrawable },
        { type = 'number', label = 'Texture (0-'..maxTexture..')', default = curTexture, min = 0, max = maxTexture }
    })
    if input then
        local newDrawable = math.floor(tonumber(input[1]) or curDrawable)
        local newTexture = math.floor(tonumber(input[2]) or curTexture)
        -- Apply to ped
        SetPedComponentVariation(ped, compId, newDrawable, newTexture, 0)
        -- If changing top (11), we might need to auto-adjust undershirt (8) and arms (3) to avoid invisible body issues.
        if compId == 11 then
            -- Simplified: if the new top has fewer than current undershirt textures, reset undershirt to default.
            local currentUndershirt = currentAppearance.components[8] or { drawable = 15, texture = 0 }
            local maxUnder = GetNumberOfPedDrawableVariations(ped, 8) - 1
            if currentUndershirt.drawable > maxUnder then
                SetPedComponentVariation(ped, 8, 15, 0, 0)  -- 15 is usually the blank undershirt
                currentAppearance.components[8] = { drawable = 15, texture = 0 }
            end
            -- Adjust arms if needed (some tops require a certain arms model to avoid holes; a full logic would use a preset map)
            -- For simplicity, just ensure arms component isn't out of range for new top
            local maxArms = GetNumberOfPedDrawableVariations(ped, 3) - 1
            local curArms = currentAppearance.components[3] and currentAppearance.components[3].drawable or 0
            if curArms > maxArms then
                SetPedComponentVariation(ped, 3, 0, 0, 0)
                currentAppearance.components[3] = { drawable = 0, texture = 0 }
            end
        end
        -- Update currentAppearance
        currentAppearance.components = currentAppearance.components or {}
        currentAppearance.components[compId] = { drawable = newDrawable, texture = newTexture }
    end
end)

-- Clothing helper: change a prop (hats, glasses, ears, watch, bracelet)
RegisterNetEvent('Radium:Appearance:ChangeProp', function(category)
    local ped = PlayerPedId()
    category = tostring(category)
    local propMap = { hat = 0, glasses = 1, ears = 2, watch = 6, bracelet = 7 }
    local propId = propMap[category]
    if propId == nil then return end
    local current = currentAppearance.props and currentAppearance.props[propId] or { drawable = -1, texture = 0 }
    local curDrawable = current.drawable or -1
    local curTexture = current.texture or 0
    local maxDrawable = GetNumberOfPedPropDrawableVariations(ped, propId) - 1
    if maxDrawable < -1 then maxDrawable = -1 end
    local maxTexture = 0
    if curDrawable >= 0 then 
        maxTexture = GetNumberOfPedPropTextureVariations(ped, propId, curDrawable) - 1 
        if maxTexture < 0 then maxTexture = 0 end
    end
    local input = lib.inputDialog('Change '..category, {
        { type = 'number', label = 'Prop ID (0-'..maxDrawable..' , -1 None)', default = curDrawable, min = -1, max = maxDrawable },
        { type = 'number', label = 'Texture (0-'..maxTexture..')', default = curTexture, min = 0, max = maxTexture }
    })
    if input then
        local newDrawable = math.floor(tonumber(input[1]) or curDrawable)
        local newTexture = math.floor(tonumber(input[2]) or 0)
        if newDrawable < 0 then
            -- Remove prop
            ClearPedProp(ped, propId)
        else
            SetPedPropIndex(ped, propId, newDrawable, newTexture, true)
        end
        -- Update currentAppearance
        currentAppearance.props = currentAppearance.props or {}
        if newDrawable < 0 then
            currentAppearance.props[propId] = { drawable = -1, texture = 0 }
        else
            currentAppearance.props[propId] = { drawable = newDrawable, texture = newTexture }
        end
    end
end)

-- Clothing helper: open tattoo menu (list available tattoos and option to remove all)
local function openTattooMenu()
    local options = {}
    -- Option to clear all tattoos
    table.insert(options, {
        title = "Remove All Tattoos",
        description = "Clear all current tattoos",
        event = "Radium:Appearance:ClearTattoos"
    })
    -- List each tattoo from config as purchasable
    for index, tat in ipairs(Config.Tattoos or {}) do
        table.insert(options, {
            title = tat.name .. " ("..tat.part..")",
            description = "Apply this tattoo",
            args = index,
            event = "Radium:Appearance:ApplyTattoo"
        })
    end
    lib.registerContext({ id = 'radium:tattooMenu', title = 'Tattoo Parlor', options = options })
    lib.showContext('radium:tattooMenu')
end

-- Event: Apply a selected tattoo from the Config.Tattoos list
RegisterNetEvent('Radium:Appearance:ApplyTattoo', function(tattooIndex)
    local ped = PlayerPedId()
    local t = Config.Tattoos and Config.Tattoos[tonumber(tattooIndex)]
    if not t then return end
    local isMale = (GetEntityModel(ped) == GetHashKey('mp_m_freemode_01'))
    local collection = t.collection
    local overlay = isMale and t.maleOverlay or t.femaleOverlay
    if collection and overlay then
        -- Apply tattoo to ped
        AddPedDecorationFromHashes(ped, GetHashKey(collection), GetHashKey(overlay))
        -- Update currentAppearance tattoos list
        currentAppearance.tattoos = currentAppearance.tattoos or {}
        -- Avoid duplicates
        for _, existing in ipairs(currentAppearance.tattoos) do
            if existing.collection == collection and existing.overlay == overlay then
                return -- already applied
            end
        end
        table.insert(currentAppearance.tattoos, { collection = collection, overlay = overlay })
    end
end)

-- Event: Clear all tattoos from player
RegisterNetEvent('Radium:Appearance:ClearTattoos', function()
    local ped = PlayerPedId()
    ClearPedDecorations(ped)
    currentAppearance.tattoos = {}
    lib.notify({ title = 'Tattoos', description = 'All tattoos have been removed.', type = 'inform' })
end)

-- FINALIZE: Save appearance changes and pay at Plastic Surgeon
RegisterNetEvent('Radium:Appearance:SavePlastic', function()
    -- Determine which categories were changed by comparing to original appearance (as loaded)
    local orig = currentAppearanceOriginal or {}  -- (we'll set this when menu opens)
    local changes = { heritage=false, faceFeatures=false, headOverlays=false, facialHair=false, hair=false, eyeColor=false }
    -- Heritage
    if orig.headBlend and currentAppearance.headBlend then
        local hb1, hb2 = orig.headBlend, currentAppearance.headBlend
        if hb1.shapeFirst ~= hb2.shapeFirst or hb1.shapeSecond ~= hb2.shapeSecond or 
           hb1.skinFirst ~= hb2.skinFirst or hb1.skinSecond ~= hb2.skinSecond or
           string.format("%.2f", hb1.shapeMix) ~= string.format("%.2f", hb2.shapeMix) or 
           string.format("%.2f", hb1.skinMix) ~= string.format("%.2f", hb2.skinMix) then
            changes.heritage = true
        end
    elseif orig.headBlend or currentAppearance.headBlend then
        changes.heritage = true
    end
    -- Face features
    if orig.faceFeatures and currentAppearance.faceFeatures then
        for i=0,19 do
            local v1 = orig.faceFeatures[tostring(i)] or orig.faceFeatures[i] or 0.0
            local v2 = currentAppearance.faceFeatures[tostring(i)] or currentAppearance.faceFeatures[i] or 0.0
            if string.format("%.2f", v1) ~= string.format("%.2f", v2) then
                changes.faceFeatures = true; break
            end
        end
    elseif orig.faceFeatures or currentAppearance.faceFeatures then
        changes.faceFeatures = true
    end
    -- Head overlays (excluding facial hair which we count separately)
    local overlayCats = {0,2,3,4,5,6,7,8,9,10,11,12}
    for _, id in ipairs(overlayCats) do
        local o1 = orig.headOverlays and orig.headOverlays[id] or orig.headOverlays and orig.headOverlays[tostring(id)]
        local o2 = currentAppearance.headOverlays and currentAppearance.headOverlays[id] or currentAppearance.headOverlays and currentAppearance.headOverlays[tostring(id)]
        local style1 = o1 and o1.style or 255
        local style2 = o2 and o2.style or 255
        local op1 = o1 and string.format("%.2f", o1.opacity or 1.0) or "1.00"
        local op2 = o2 and string.format("%.2f", o2.opacity or 1.0) or "1.00"
        local col1 = o1 and o1.color or -1
        local col2 = o2 and o2.color or -1
        if style1 ~= style2 or op1 ~= op2 or (col1 ~= col2 and col1 ~= -1) then
            changes.headOverlays = true; break
        end
    end
    -- Facial hair (overlay 1)
    local beard1 = orig.headOverlays and orig.headOverlays[1]
    local beard2 = currentAppearance.headOverlays and currentAppearance.headOverlays[1]
    local bdStyle1 = beard1 and beard1.style or 255
    local bdStyle2 = beard2 and beard2.style or 255
    local bdCol1 = beard1 and beard1.color or -1
    local bdCol2 = beard2 and beard2.color or -1
    if bdStyle1 ~= bdStyle2 or bdCol1 ~= bdCol2 then
        changes.facialHair = true
    end
    -- Hair
    if orig.hair and currentAppearance.hair then
        if orig.hair.style ~= currentAppearance.hair.style or 
           orig.hair.color ~= currentAppearance.hair.color or 
           orig.hair.highlight ~= currentAppearance.hair.highlight then
            changes.hair = true
        end
    elseif orig.hair or currentAppearance.hair then
        changes.hair = true
    end
    -- Eye color
    if (orig.eyeColor or 0) ~= (currentAppearance.eyeColor or 0) then
        changes.eyeColor = true
    end

    -- Trigger server save with the changes and new appearance
    TriggerServerEvent('Radium:Appearance:SaveAppearance', currentAppearance, changes, "Plastic")
end)

-- FINALIZE: Save appearance changes and pay at Clothing Shop
RegisterNetEvent('Radium:Appearance:SaveClothing', function()
    local orig = currentAppearanceOriginal or {}
    local changes = { mask=false, top=false, undershirt=false, arms=false, pants=false, shoes=false, bag=false, hat=false, glasses=false, ears=false, watch=false, bracelet=false, tattoos=false }
    -- Components
    local compIds = { mask=1, top=11, undershirt=8, arms=3, pants=4, shoes=6, bag=5 }
    for cat, compId in pairs(compIds) do
        local origComp = orig.components and orig.components[compId]
        local newComp = currentAppearance.components and currentAppearance.components[compId]
        local origDraw = origComp and origComp.drawable or 0
        local newDraw = newComp and newComp.drawable or 0
        local origTex  = origComp and origComp.texture or 0
        local newTex  = newComp and newComp.texture or 0
        if origDraw ~= newDraw or origTex ~= newTex then
            changes[cat] = true
        end
    end
    -- Props
    local propIds = { hat=0, glasses=1, ears=2, watch=6, bracelet=7 }
    for cat, propId in pairs(propIds) do
        local origProp = orig.props and orig.props[propId]
        local newProp = currentAppearance.props and currentAppearance.props[propId]
        local origDraw = origProp and origProp.drawable or -1
        local newDraw = newProp and newProp.drawable or -1
        local origTex  = origProp and origProp.texture or 0
        local newTex  = newProp and newProp.texture or 0
        if origDraw ~= newDraw or origTex ~= newTex then
            changes[cat] = true
        end
    end
    -- Tattoos
    local origTats = orig.tattoos or {}
    local newTats = currentAppearance.tattoos or {}
    -- If number of tattoos changed or any difference, mark true
    if #origTats ~= #newTats then
        changes.tattoos = true
    else
        -- compare content
        for _, ot in ipairs(origTats) do
            local found = false
            for _, nt in ipairs(newTats) do
                if ot.collection == nt.collection and ot.overlay == nt.overlay then found = true; break end
            end
            if not found then changes.tattoos = true; break end
        end
    end

    TriggerServerEvent('Radium:Appearance:SaveAppearance', currentAppearance, changes, "Clothing")
end)

-- Define and open the Plastic Surgeon main context menu
local function openPlasticSurgeonMenu()
    -- Save a copy of currentAppearance as original reference
    currentAppearanceOriginal = json.decode(json.encode(currentAppearance)) or {}
    lib.registerContext({
        id = 'radium:plasticMenu',
        title = 'Plastic Surgeon',
        options = {
            { title = 'Heritage',      description = 'Adjust parents & resemblance',    event = 'Radium:Appearance:OpenHeritage' },
            { title = 'Face Shape',    description = 'Adjust facial structure',        event = 'Radium:Appearance:OpenFaceFeatures' },
            { title = 'Facial Overlays', description = 'Blemishes, Aging, Makeup, etc.', event = 'Radium:Appearance:OpenOverlays' },
            { title = 'Eye Color',     description = 'Change eye color',               event = 'Radium:Appearance:ChangeEyes' },
            { title = 'Hair Style',    description = 'Change hairstyle',               event = 'Radium:Appearance:OpenHair' },
            { title = 'Facial Hair',   description = 'Change beard/mustache',          event = 'Radium:Appearance:OpenBeard' },
            { title = 'Finish & Save', description = 'Save changes (pay fee)',        event = 'Radium:Appearance:SavePlastic' }
        }
    })
    lib.showContext('radium:plasticMenu')
end

-- Define and open the Clothing Shop main context menu
local function openClothingShopMenu()
    currentAppearanceOriginal = json.decode(json.encode(currentAppearance)) or {}
    lib.registerContext({
        id = 'radium:clothingMenu',
        title = 'Clothing Store',
        options = {
            { title = 'Masks',      description = 'Change mask',         args = 'mask',       event = 'Radium:Appearance:ChangeClothing' },
            { title = 'Tops/Jackets', description = 'Change top/jacket', args = 'top',        event = 'Radium:Appearance:ChangeClothing' },
            { title = 'Undershirts', description = 'Change undershirt',  args = 'undershirt', event = 'Radium:Appearance:ChangeClothing' },
            { title = 'Arms/Gloves', description = 'Adjust arms or gloves', args = 'arms',   event = 'Radium:Appearance:ChangeClothing' },
            { title = 'Pants',      description = 'Change pants/shorts', args = 'pants',      event = 'Radium:Appearance:ChangeClothing' },
            { title = 'Shoes',      description = 'Change shoes',        args = 'shoes',      event = 'Radium:Appearance:ChangeClothing' },
            { title = 'Bags/Parachutes', description = 'Change bag/backpack', args = 'bag',  event = 'Radium:Appearance:ChangeClothing' },
            { title = 'Hats/Helmets', description = 'Change hat/helmet', args = 'hat',       event = 'Radium:Appearance:ChangeProp' },
            { title = 'Glasses',   description = 'Change eyewear',       args = 'glasses',   event = 'Radium:Appearance:ChangeProp' },
            { title = 'Earrings',  description = 'Change ear accessory', args = 'ears',      event = 'Radium:Appearance:ChangeProp' },
            { title = 'Watches',   description = 'Change watch',         args = 'watch',     event = 'Radium:Appearance:ChangeProp' },
            { title = 'Bracelets', description = 'Change bracelet',      args = 'bracelet',  event = 'Radium:Appearance:ChangeProp' },
            { title = 'Tattoos',   description = 'View tattoo options',  event = 'Radium:Appearance:OpenTattoos' },
            { title = 'Finish & Save', description = 'Save outfit (pay fee)', event = 'Radium:Appearance:SaveClothing' }
        }
    })
    lib.showContext('radium:clothingMenu')
end

-- Register events for menu options (mapping to helper functions)
RegisterNetEvent('Radium:Appearance:OpenHeritage',    openHeritageMenu)
RegisterNetEvent('Radium:Appearance:OpenFaceFeatures', openFaceFeaturesMenu)
RegisterNetEvent('Radium:Appearance:OpenOverlays',    openFacialOverlaysMenu)
RegisterNetEvent('Radium:Appearance:ChangeEyes',      changeEyeColor)
RegisterNetEvent('Radium:Appearance:OpenHair',        openHairMenu)
RegisterNetEvent('Radium:Appearance:OpenBeard',       openBeardMenu)
RegisterNetEvent('Radium:Appearance:OpenTattoos',     openTattooMenu)

-- Main thread: monitor player location for Plastic Surgeon / Clothing Shop access
CreateThread(function()
    local player = PlayerPedId()
    while true do
        local wait = 1000
        local pedCoords = GetEntityCoords(PlayerPedId())
        -- Check Plastic Surgery locations
        for _, loc in ipairs(Config.PlasticSurgery.Locations or {}) do
            local dist = #(pedCoords - vector3(loc.x, loc.y, loc.z))
            if dist < 10.0 then
                wait = 0
                if dist < 2.0 then
                    DrawTxt("Press [E] to visit Plastic Surgeon", 0.5, 0.88)  -- draw a help text (DrawTxt is a hypothetical helper)
                    if IsControlJustReleased(0, 38) then  -- 38 = E
                        if GetEntityModel(PlayerPedId()) ~= GetHashKey('mp_m_freemode_01') 
                           and GetEntityModel(PlayerPedId()) ~= GetHashKey('mp_f_freemode_01') then
                            lib.notify({title='Plastic Surgeon', description='This service is only available for MP characters.', type='error'})
                        else
                            openPlasticSurgeonMenu()
                        end
                    end
                end
            end
        end
        -- Check Clothing Shop locations
        for _, loc in ipairs(Config.ClothingShops.Locations or {}) do
            local dist = #(pedCoords - vector3(loc.x, loc.y, loc.z))
            if dist < 10.0 then
                wait = 0
                if dist < 2.0 then
                    DrawTxt("Press [E] to browse Clothing", 0.5, 0.88)
                    if IsControlJustReleased(0, 38) then
                        if GetEntityModel(PlayerPedId()) ~= GetHashKey('mp_m_freemode_01') 
                           and GetEntityModel(PlayerPedId()) ~= GetHashKey('mp_f_freemode_01') then
                            lib.notify({title='Clothing Store', description='Only freemode characters can change outfits here.', type='error'})
                        else
                            openClothingShopMenu()
                        end
                    end
                end
            end
        end
        Wait(wait)
    end
end)

-- Utility: simple text drawing on screen
function DrawTxt(text, x, y)
    SetTextFont(0); SetTextProportional(0); SetTextScale(0.34, 0.34)
    SetTextColour(255, 255, 255, 255); SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextOutline(); SetTextCentre(1)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

Radium = Radium or {}
Radium.PlasticSurgery = Radium.PlasticSurgery or {}

function Radium.PlasticSurgery:Open()
    destroyPreviewCam()

    local ped = PlayerPedId()
    local model = IsPedMale(ped) and `mp_m_freemode_01` or `mp_f_freemode_01`
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end
    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)

    SetEntityCoords(ped, -1035.71, -2731.87, 13.0, false, false, false, true)
    SetEntityHeading(ped, 0.0)
    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, true, false)
    DoScreenFadeIn(500)

    local result = lib.inputDialog("Plastic Surgeon", {
        { type = 'input', label = 'Hair Style', placeholder = 'Enter hair style ID', icon = 'scissors' },
        { type = 'input', label = 'Beard Style', placeholder = 'Enter beard style ID', icon = 'user' }
    })

    if not result then return end

    local hair = tonumber(result[1]) or 0
    local beard = tonumber(result[2]) or 0

    SetPedComponentVariation(ped, 2, hair, 0, 0)
    SetPedHeadOverlay(ped, 1, beard, 1.0)

    TriggerServerEvent("radium-core:server:saveAppearance", {
        model = model,
        hair = hair,
        beard = beard
    })

    -- Finish with spawn selector
    TriggerEvent("radium-core:client:openSpawnSelector")
end


RegisterNetEvent('Radium:Appearance:OpenPlasticMenu', function()
    Radium.PlasticSurgery:Open()
end)



