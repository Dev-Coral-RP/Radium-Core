-- client/main.lua
-- Radium-Core Framework: ox_lib menus + multi-character integration

local lib = exports.ox_lib
local Keys = { ['E'] = 38 }

print("[Radium-Core] main.lua loaded, registering menus...")

-- Helper: build a simple numbered list menu
local function buildListMenu(min, max, label, applyFunc)
    local items = {}
    for i = min, max do
        items[#items + 1] = {
            label = string.format("%s #%d", label, i),
            args = { index = i, func = applyFunc }
        }
    end
    return items
end

-- == MENU REGISTRATIONS USING NEW API ==

-- Root Customization Menu
lib.registerMenu({
    id       = 'customization_menu',
    title    = 'Character Customization',
    position = 'top-right',
    options  = {
        { label = 'Appearance',      args = { submenu = 'appearance_menu' } },
        { label = 'Clothing',        args = { submenu = 'clothing_menu'  } },
        { label = 'Tattoos',         args = { submenu = 'tattoo_menu'    } },
        { label = 'Barber',          args = { submenu = 'barber_menu'    } },
        { label = 'Plastic Surgeon', args = { submenu = 'surgery_menu'   } },
        { label = 'Close',           close = true }
    },
}, function(selected, scrollIndex, args)
    if args.submenu then
        lib.showMenu(args.submenu)
    end
end)

-- Appearance Menu
lib.registerMenu({
    id       = 'appearance_menu',
    title    = 'Appearance',
    position = 'top-right',
    options  = {
        { label = 'Hair Style',      args = { submenu = 'hair_style_menu' } },
        { label = 'Hair Color',      args = { submenu = 'hair_color_menu' } },
        { label = 'Highlight Color', args = { submenu = 'hair_highlight_menu' } },
        { label = 'Overlays',        args = { submenu = 'overlay_types_menu' } },
        { label = 'Back',            args = { submenu = 'customization_menu'} }
    }
}, function(selected, _, args)
    if args.submenu then lib.showMenu(args.submenu) end
end)

-- Hair Style Menu
lib.registerMenu({
    id       = 'hair_style_menu',
    title    = 'Hair Style',
    position = 'top-right',
    options  = buildListMenu(0, GetNumberOfPedDrawableVariations(PlayerPedId(),2)-1, 'Hair Style', function(ped,index)
        SetPedComponentVariation(ped,2,index,0,2)
    end)
}, function(selected, _, args)
    args.func(PlayerPedId(), args.index)
end)

-- Hair Color Menu
lib.registerMenu({
    id       = 'hair_color_menu',
    title    = 'Hair Color',
    position = 'top-right',
    options  = buildListMenu(0,63,'Hair Color', function(ped,index)
        local _, hl = GetPedHairColor(ped)
        SetPedHairColor(ped,index,hl)
    end)
}, function(_, _, args)
    args.func(PlayerPedId(), args.index)
end)

-- Highlight Color Menu
lib.registerMenu({
    id       = 'hair_highlight_menu',
    title    = 'Highlight Color',
    position = 'top-right',
    options  = buildListMenu(0,63,'Highlight', function(ped,index)
        local primary,_ = GetPedHairColor(ped)
        SetPedHairColor(ped,primary,index)
    end)
}, function(_, _, args)
    args.func(PlayerPedId(), args.index)
end)

-- Overlays Type Menu
lib.registerMenu({
    id       = 'overlay_types_menu',
    title    = 'Overlay Types',
    position = 'top-right',
    options  = {
        { label = 'Blemishes', args = { overlay = 1 } },
        { label = 'Beard',     args = { overlay = 2 } },
        { label = 'Eyebrows',  args = { overlay = 3 } },
        { label = 'Back',      args = { submenu = 'appearance_menu' } }
    }
}, function(_, _, args)
    if args.submenu then
        lib.showMenu(args.submenu)
    elseif args.overlay then
        lib.showMenu('overlay_'..args.overlay..'_menu')
    end
end)

-- Overlay Menus
for i=1,3 do
    lib.registerMenu({
        id       = 'overlay_'..i..'_menu',
        title    = 'Overlay '..i,
        position = 'top-right',
        options  = buildListMenu(0,GetNumberOfPedHeadOverlayValues(i)-1,'Overlay', function(ped,index)
            SetPedHeadOverlay(ped,i,index,1.0)
        end)
    }, function(_, _, args)
        args.func(PlayerPedId(), args.index)
    end)
end

-- Clothing Menu
lib.registerMenu({
    id       = 'clothing_menu',
    title    = 'Clothing',
    position = 'top-right',
    options  = {
        { label='Mask',        args={comp=1} },
        { label='Hair',        args={comp=2} },
        { label='Torso',       args={comp=3} },
        { label='Legs',        args={comp=4} },
        { label='Bags',        args={comp=5} },
        { label='Shoes',       args={comp=6} },
        { label='Accessories', args={comp=7} },
        { label='Undershirt',  args={comp=8} },
        { label='Armor',       args={comp=9} },
        { label='Decals',      args={comp=10}},
        { label='Torso 2',     args={comp=11}},
        { label='Back',        args={submenu='customization_menu'} }
    }
}, function(_, _, args)
    if args.comp then
        ShowComponent(args.comp, 'Component '..args.comp)
    elseif args.submenu then
        lib.showMenu(args.submenu)
    end
end)

-- Tattoo, Barber, Surgery menus would follow the same pattern...

-- Blips & Markers
CreateThread(function()
    for _,shop in ipairs(Config.Shops) do
        local b = AddBlipForCoord(shop.coords)
        SetBlipSprite(b, shop.blip.sprite)
        SetBlipDisplay(b, 4)
        SetBlipScale(b, 0.8)
        SetBlipColour(b, shop.blip.color)
        SetBlipAsShortRange(b, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(shop.blip.text)
        EndTextCommandSetBlipName(b)
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        for _,shop in ipairs(Config.Shops) do
            local dist = #(pos - shop.coords)
            if dist < 20 then
                sleep = 0
                DrawMarker(2, shop.coords.x, shop.coords.y, shop.coords.z - 0.99, 0,0,0,0,0,0,0.3,0.3,0.3,255,255,255,100)
                if dist < Config.DrawDistance then
                    lib.showTextUI(('Press ~%s~ to open %s'):format(Config.Key, shop.blip.text))
                    if IsControlJustReleased(0, Keys[Config.Key]) then
                        lib.hideTextUI()
                        if shop.type == 'surgeon' then
                            lib.showMenu('customization_menu')
                        else
                            lib.showMenu(shop.type..'_menu')
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- Character Created Hook & Test Command
RegisterNetEvent('Radium:CharacterCreated', function()
    print('[Radium-Core] CharacterCreated => opening customization_menu')
    lib.showMenu('customization_menu')
end)

RegisterCommand('testmenu', function()
    print('[Radium-Core] /testmenu invoked')
    lib.showMenu('customization_menu')
end, false)
