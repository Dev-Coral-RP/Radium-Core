local oxmysql = exports.oxmysql

-- Save appearance data to database and charge the player
RegisterNetEvent('Radium:Appearance:SaveAppearance', function(newAppearance, changes, module)
    local src = source
    if type(newAppearance) ~= "table" or type(changes) ~= "table" or type(module) ~= "string" then
        return -- invalid data
    end

    -- Identify the character record to update. (This assumes your Radium Core has a way to get current char identifier.)
    local charId = nil 
    if exports["radium-core"] and exports["radium-core"]:GetCharId(src) then
        charId = exports["radium-core"]:GetCharId(src)
    end
    -- If no export available, you might store charId in a player identifier on login:
    -- charId = Player(src).state.charId or similar, depending on your framework.

    if not charId then
        print("[Radium:Appearance] Could not determine character ID for player "..src)
        return
    end

    -- Calculate total cost based on changes made
    local totalCost = 0
    if module == "Plastic" then
        -- Plastic surgeon pricing
        if changes.heritage then    totalCost = totalCost + (Config.PlasticSurgery.Prices.heritage or 0)    end
        if changes.faceFeatures then totalCost = totalCost + (Config.PlasticSurgery.Prices.faceFeatures or 0) end
        if changes.headOverlays then totalCost = totalCost + (Config.PlasticSurgery.Prices.headOverlays or 0) end
        if changes.facialHair then  totalCost = totalCost + (Config.PlasticSurgery.Prices.facialHair or 0)  end
        if changes.hair then        totalCost = totalCost + (Config.PlasticSurgery.Prices.hair or 0)        end
        if changes.eyeColor then    totalCost = totalCost + (Config.PlasticSurgery.Prices.eyeColor or 0)    end
    elseif module == "Clothing" then
        -- Clothing shop pricing
        if changes.mask then      totalCost = totalCost + (Config.ClothingShops.Prices.mask or 0)      end
        if changes.top then       totalCost = totalCost + (Config.ClothingShops.Prices.top or 0)       end
        if changes.undershirt then totalCost = totalCost + (Config.ClothingShops.Prices.undershirt or 0) end
        if changes.arms then      totalCost = totalCost + (Config.ClothingShops.Prices.arms or 0)      end
        if changes.pants then     totalCost = totalCost + (Config.ClothingShops.Prices.pants or 0)     end
        if changes.shoes then     totalCost = totalCost + (Config.ClothingShops.Prices.shoes or 0)     end
        if changes.bag then       totalCost = totalCost + (Config.ClothingShops.Prices.bag or 0)       end
        if changes.hat then       totalCost = totalCost + (Config.ClothingShops.Prices.hat or 0)       end
        if changes.glasses then   totalCost = totalCost + (Config.ClothingShops.Prices.glasses or 0)   end
        if changes.ears then      totalCost = totalCost + (Config.ClothingShops.Prices.ears or 0)      end
        if changes.watch then     totalCost = totalCost + (Config.ClothingShops.Prices.watch or 0)     end
        if changes.bracelet then  totalCost = totalCost + (Config.ClothingShops.Prices.bracelet or 0)  end
        if changes.tattoos then   totalCost = totalCost + (Config.ClothingShops.Prices.tattoos or 0)   end
    end

    -- Charge the player
    local paid = true
    if totalCost > 0 then
        -- Integrate with your money system. Example for QBCore:
        -- local Player = exports['qb-core']:GetCoreObject().Functions.GetPlayer(src)
        -- if Player.PlayerData.money.cash >= totalCost then
        --     Player.Functions.RemoveMoney('cash', totalCost, 'appearance-changes')
        -- else
        --     paid = false
        -- end

        -- Placeholder: always assume payment successful for this example.
        -- You should replace this with actual money deduction logic.
        print(("Charging $%d to player %d for appearance changes"):format(totalCost, src))
    end

    if not paid then
        TriggerClientEvent('ox_lib:notify', src, {title='Appearance', description='Not enough money to pay for changes.', type='error'})
        return
    end

    -- Ensure model is one of allowed values before saving
    if newAppearance.model ~= 'mp_m_freemode_01' and newAppearance.model ~= 'mp_f_freemode_01' then
        print("[Radium:Appearance] Warning: attempted to save appearance with invalid model.")
        return
    end

    -- Convert appearance table to JSON string
    local appearanceJSON = json.encode(newAppearance)
    -- Save to database
    local updateQuery = 'UPDATE characters SET appearance = ? WHERE id = ?'
    local result = oxmysql:update(updateQuery, { appearanceJSON, charId })
    if result and result.affectedRows > 0 then
        TriggerClientEvent('ox_lib:notify', src, {title='Appearance', description='Appearance saved successfully!', type='success'})
    else
        print("[Radium:Appearance] Database save failed for charId: "..charId)
    end
end)

-- Load character appearance on spawn/selection
RegisterNetEvent('Radium:Appearance:LoadAppearance', function(charId)
    local src = source
    if not charId then return end
    local result = oxmysql:singleSync('SELECT appearance, model FROM characters WHERE id = ?', { charId })
    local appearanceData = result and result.appearance or nil
    if appearanceData then
        TriggerClientEvent('Radium:Appearance:Apply', src, appearanceData)
    else
        -- No appearance data, possibly a new character
        TriggerClientEvent('Radium:Appearance:Apply', src, "{}")
    end
end)

-- When a new character is created, open the Plastic Surgeon menu automatically
RegisterNetEvent('Radium:CharacterCreated', function(charId, gender)
    local src = source
    if not charId then return end
    -- Set the player ped to the chosen gender model
    local model = (gender == 'female' or gender == 'F') and 'mp_f_freemode_01' or 'mp_m_freemode_01'
    TriggerClientEvent('Radium:Appearance:Apply', src, json.encode({model = model}))  -- spawn default appearance
    TriggerClientEvent('Radium:Appearance:OpenPlasticMenu', src)
end)

-- Allow client to trigger opening the plastic surgery menu (after new character creation)
RegisterNetEvent('Radium:Appearance:OpenPlasticMenu', function()
    local src = source
    TriggerClientEvent('Radium:Appearance:OpenHeritage', src)  -- this will effectively open the Plastic Surgeon menu on client side
    -- (Alternatively, directly trigger the function to open menu context if needed)
end)
