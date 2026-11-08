--!nonstrict
-- Polls the systemd --user service state and publishes it to shared state.

local function unit()
    local u = noctalia.getConfig("unit")
    if u == nil or u == "" then
        return "proxy-tunnel"
    end
    return u
end

local function poll()
    noctalia.runAsync("systemctl --user is-active --quiet " .. unit(), function(result)
        noctalia.state.set("active", result.exitCode == 0)
    end)
end

noctalia.setUpdateInterval(2000)
poll()

function update()
    poll()
end
