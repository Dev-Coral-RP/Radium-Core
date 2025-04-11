Radium = Radium or {}

function Radium.GetJob(src)
    local p = Radium.GetPlayer(src)
    return p and p.job or "unemployed"
end


function Radium.GetMoney(src, account)
    local p = Radium.GetPlayer(src)
    return p and p.money[account] or 0
end

function Radium.SetMoney(src, account, amount)
    local p = Radium.GetPlayer(src)
    if not p then return end
    p.money[account] = amount
end

-- Optional: add/remove wrappers
function Radium.AddMoney(src, account, amount)
    local p = Radium.GetPlayer(src)
    if not p then return end
    p.money[account] = (p.money[account] or 0) + amount
end

function Radium.RemoveMoney(src, account, amount)
    local p = Radium.GetPlayer(src)
    if not p then return end
    p.money[account] = math.max(0, (p.money[account] or 0) - amount)
end

function Radium.IsJobBoss(src)
    local player = Radium.Players[src]
    if not player then return false end

    local job = Radium.Config.Jobs[player.job]
    if not job then return false end

    local grade = job.grades[player.job_grade]
    return grade and grade.isBoss == true
end
