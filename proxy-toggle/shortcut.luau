--!nonstrict
-- Stateful control-center tile: lit = tunnel active, dim = direct.
-- Click runs the configured toggle command.

local function setting(key, fallback)
    local v = noctalia.getConfig(key)
    if v == nil or v == "" then
        return fallback
    end
    return v
end

local function render(active)
    shortcut.setLabel(setting("label", "Proxy"))
    shortcut.setIcon(setting("icon", "world"))
    shortcut.setActive(active == true)
    shortcut.setEnabled(true)
end

render(noctalia.state.get("active") == true)

noctalia.state.watch("active", function(v)
    render(v == true)
end)

function onConfigChanged()
    render(noctalia.state.get("active") == true)
end

function onClick()
    noctalia.runAsync(setting("toggle_command", "proxy-tunnel-toggle"))
end
