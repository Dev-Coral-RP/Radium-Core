RegisterNetEvent('radium-logs:characterCreated', function(src, csn)
    -- Replace this with your actual Discord logging logic
    print(('Character created by [%s] with CSN: %s'):format(src, csn))
end)

RegisterNetEvent('radium-logs:characterDeleted', function(src, csn)
    -- Replace this with your actual Discord logging logic
    print(('Character deleted by [%s] with CSN: %s'):format(src, csn))
end)