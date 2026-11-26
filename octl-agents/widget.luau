--!nonstrict
-- Bar widget: dim glyph when nothing is happening, busy count in accent color
-- while agents run, alert count in alert color when sessions wait for the user
-- (permission prompts / errors). Click toggles the session panel.

local PLUGIN_ID = "tomaswade/octl-agents"
local MAX_TOOLTIP_ROWS = 12

local function setting(key, fallback)
    local v = noctalia.getConfig(key)
    if v == nil or v == "" then
        return fallback
    end
    return v
end

local function statusTag(status)
    if status == "PERMISSION" then
        return "?"
    elseif status == "ERROR" then
        return "!"
    elseif status == "RETRY" then
        return "↻"
    elseif status == "BUSY" then
        return "▶"
    end
    return "○"
end

local function summaryLine(snap)
    local c = snap.counts or {}
    local parts = {}
    if (c.permission or 0) > 0 then
        table.insert(parts, string.format("%d %s", c.permission, noctalia.tr("summary.waiting")))
    end
    if (c.error or 0) > 0 then
        table.insert(parts, string.format("%d %s", c.error, noctalia.tr("summary.errored")))
    end
    if (c.retry or 0) > 0 then
        table.insert(parts, string.format("%d %s", c.retry, noctalia.tr("summary.retrying")))
    end
    if (c.busy or 0) > 0 then
        table.insert(parts, string.format("%d %s", c.busy, noctalia.tr("summary.running")))
    end
    if (c.idle or 0) > 0 then
        table.insert(parts, string.format("%d %s", c.idle, noctalia.tr("summary.idle")))
    end
    if #parts == 0 then
        return noctalia.tr("tooltip.empty")
    end
    return table.concat(parts, " · ")
end

local function tooltipText(snap)
    local lines = { summaryLine(snap) }
    local sessions = snap.sessions or {}
    for i, s in ipairs(sessions) do
        if i > MAX_TOOLTIP_ROWS then
            table.insert(lines, string.format("… +%d", #sessions - MAX_TOOLTIP_ROWS))
            break
        end
        local line = statusTag(s.status) .. " " .. (s.title ~= "" and s.title or s.sessionId)
        if s.detail ~= nil and s.detail ~= "" then
            line = line .. " · " .. s.detail
        end
        table.insert(lines, line)
    end
    return table.concat(lines, "\n")
end

local function render(snap)
    snap = snap or noctalia.state.get("snap")
    local color = "on_surface_variant"
    local count = nil
    local offline = snap == nil or snap.online ~= true

    if not offline then
        local c = snap.counts or {}
        local alert = (c.permission or 0) + (c.error or 0)
        if alert > 0 then
            color = setting("alert_color", "error")
            count = alert
        elseif (c.busy or 0) > 0 then
            color = setting("busy_color", "primary")
            count = c.busy
        end
    end

    local content = {
        ui.glyph({ name = setting("glyph", "brain"), color = color }),
    }
    if count ~= nil then
        table.insert(content, ui.label({ text = tostring(count), color = color, fontWeight = "bold" }))
    end
    barWidget.render(ui.row({ gap = 4, align = "center" }, content))

    if offline then
        barWidget.setTooltip(noctalia.tr("tooltip.offline"))
    else
        barWidget.setTooltip(tooltipText(snap))
    end
end

render()

noctalia.state.watch("snap", function(snap)
    render(snap)
end)

function onClick()
    noctalia.runAsync({ "noctalia", "msg", "panel-toggle", PLUGIN_ID .. ":sessions" })
end

function onConfigChanged()
    render()
end
