AddEventHandler('playerJoining', function(source, name, deferrals)
    deferrals.defer()
    Wait(100)

    deferrals.update("Loading Radium-Core...")
    Wait(100)

    deferrals.done()
    TriggerEvent('radium-core:playerReady', source)
end)
