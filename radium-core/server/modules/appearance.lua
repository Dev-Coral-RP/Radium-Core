-- radium-core/server/modules/appearance.lua

print("[Radium-Core] Loaded Module: appearance.lua")

Radium = Radium or {}
Radium.Appearance = Radium.Appearance or {}



-- Save appearance
-- Save outfit
RegisterNetEvent('ox_custom:saveOutfit', function(name, data)
    local src = source
    local id = GetPlayerIdentifier(src, 0)
    MySQL:insert('INSERT INTO user_outfits (identifier, name, data) VALUES (?, ?, ?)', { id, name, json.encode(data) }, function(insertId)
      TriggerClientEvent('ox_lib:notify', src, { type = 'success', text = 'Outfit saved!' })
    end)
  end)
  
  -- Return list
  RegisterNetEvent('ox_custom:requestOutfits', function()
    local src = source
    local id = GetPlayerIdentifier(src, 0)
    MySQL:fetchAll('SELECT id, name FROM user_outfits WHERE identifier = ?', { id }, function(results)
      TriggerClientEvent('ox_custom:returnOutfits', src, results)
    end)
  end)
  
  -- Load specific
  RegisterNetEvent('ox_custom:requestLoad', function(outfitId)
    local src = source
    MySQL:fetchAll('SELECT data FROM user_outfits WHERE id = ?', { outfitId }, function(results)
      if results[1] then
        local data = json.decode(results[1].data)
        TriggerClientEvent('ox_custom:loadOutfitData', src, data)
        TriggerClientEvent('ox_lib:notify', src, { type = 'success', text = 'Outfit loaded!' })
      end
    end)
  end)
