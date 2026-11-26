--!nonstrict
-- Detail panel: all non-archived opencode sessions grouped by state, re-rendered
-- on every poll while open. Headings show group counts; rows show a colored
-- status marker, the session title and (when present) the actionable detail —
-- the command awaiting approval, the question being asked, or the error message.

local isOpen = false

local function statusColor(status)
    if status == "PERMISSION" or status == "ERROR" then
        return "error"
    elseif status == "RETRY" or status == "BUSY" then
        return "primary"
    end
    return "on_surface_variant"
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

local function sessionRow(s)
    local titleChildren = {
        ui.label({ text = s.title ~= "" and s.title or s.sessionId, color = "on_surface", maxLines = 1 }),
    }
    if s.detail ~= nil and s.detail ~= "" then
        table.insert(titleChildren, ui.label({ text = s.detail, fontSize = 11, color = statusColor(s.status), maxLines = 1 }))
    end
    return ui.row({ gap = 10, align = "center" }, {
        ui.label({ text = statusTag(s.status), color = statusColor(s.status), fontWeight = "bold" }),
        ui.column({ gap = 2, flexGrow = 1 }, titleChildren),
    })
end

local function addGroup(children, headerKey, statusSet, sessions)
    local rows = {}
    for _, s in ipairs(sessions) do
        if statusSet[s.status] then
            table.insert(rows, sessionRow(s))
        end
    end
    if #rows == 0 then
        return
    end
    table.insert(children, ui.label({
        text = noctalia.tr(headerKey) .. " (" .. #rows .. ")",
        fontWeight = "bold",
        color = "on_surface_variant",
    }))
    for _, r in ipairs(rows) do
        table.insert(children, r)
    end
end

local function render()
    local snap = noctalia.state.get("snap")
    local online = snap ~= nil and snap.online == true

    local header = ui.row({ align = "center", justify = "space_between", gap = 8 }, {
        ui.label({ text = noctalia.tr("panel.title"), fontSize = 16, fontWeight = "bold", color = "on_surface", flexGrow = 1 }),
        ui.label({
            text = online and noctalia.tr("panel.online") or noctalia.tr("panel.offline"),
            fontSize = 11,
            color = "on_surface_variant",
        }),
    })

    local body = {}
    if not online then
        table.insert(body, ui.label({ text = noctalia.tr("panel.offline_body"), color = "on_surface_variant" }))
    elseif snap.sessions == nil or #snap.sessions == 0 then
        table.insert(body, ui.label({ text = noctalia.tr("panel.empty"), color = "on_surface_variant" }))
    else
        addGroup(body, "panel.waiting", { PERMISSION = true }, snap.sessions)
        addGroup(body, "panel.errored", { ERROR = true, RETRY = true }, snap.sessions)
        addGroup(body, "panel.running", { BUSY = true }, snap.sessions)
        addGroup(body, "panel.idle", { IDLE = true, UNKNOWN = true }, snap.sessions)
    end

    panel.render(ui.column({ flexGrow = 1, gap = 16 }, {
        header,
        ui.scroll({ flexGrow = 1, gap = 12 }, body),
    }))
end

function onOpen(_context)
    isOpen = true
    render()
end

function onClose()
    isOpen = false
end

noctalia.state.watch("snap", function()
    if isOpen then
        render()
    end
end)
