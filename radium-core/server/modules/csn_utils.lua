print("[Radium-Core] Loaded: csn_utils.lua")

function GenerateCSN()
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local nums = '0123456789'
    local output = ''

    for i = 1, 3 do
        output = output .. chars:sub(math.random(#chars), math.random(#chars))
    end
    for i = 1, 4 do
        output = output .. nums:sub(math.random(#nums), math.random(#nums))
    end
    return output
end

function GenerateBloodType()
    local types = { 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-' }
    return types[math.random(1, #types)]
end