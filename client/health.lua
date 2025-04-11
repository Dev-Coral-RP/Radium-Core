Radium = Radium or {}

local downed = false

CreateThread(function()
    while true do
        Wait(1000)

        local ped = PlayerPedId()
        local health = GetEntityHealth(ped)

        -- Disable native regen if needed
        if not Radium.Config.Health.regenEnabled then
            SetPlayerHealthRechargeMultiplier(PlayerId(), 0.0)
        end

        -- Downed state trigger
        if not downed and health < Radium.Config.Health.downedThreshold then
            downed = true
            TriggerEvent("radium:playerDowned")
            TriggerServerEvent("radium:logHealthDown", health)
        end

        -- Reset if revived
        if downed and health >= Radium.Config.Health.downedThreshold then
            downed = false
        end
    end
end)

-- Example NUI notify (if you have your global notify system later)
AddEventHandler("radium:playerDowned", function()
    TriggerEvent("radium:notify", {
        type = "error",
        message = "You’re downed! Wait for medics..."
    })
end)
