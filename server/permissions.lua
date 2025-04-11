Radium = Radium or {}

Radium.Permissions = {
    ["license:example123"] = { "admin", "dev" },
    ["license:example456"] = { "mod" },
}

function Radium.HasPermission(license, group)
    local perms = Radium.Permissions[license]
    if not perms then return false end
    return Radium.TableHasValue(perms, group)
end
