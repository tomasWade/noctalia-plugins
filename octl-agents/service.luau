--!nonstrict
-- Polls `octl query snaps --json` every interval and publishes the aggregated
-- snapshot to shared plugin state as "snap":
--   { online: bool, counts: { busy, permission, error, retry, idle },
--     sessions: [ { sessionId, status, title, detail } ] }
-- Sessions are sorted by attention priority; ARCHIVED sessions are skipped.
-- octl exits non-zero with "daemon unreachable" when the daemon is down, which
-- becomes online = false.

local PRIORITY = {
    PERMISSION = 0,
    ERROR = 1,
    RETRY = 2,
    BUSY = 3,
    IDLE = 4,
    UNKNOWN = 5,
}

local MAX_TITLE_CHARS = 48

-- UTF-8 aware truncation (session titles are frequently CJK); falls back to a
-- byte cut when utf8 is unavailable.
local function truncate(s, maxChars)
    s = tostring(s or "")
    if utf8 ~= nil and utf8.len ~= nil then
        local ok, len = pcall(utf8.len, s)
        if ok and type(len) == "number" then
            if len <= maxChars then
                return s
            end
            for i = maxChars, 1, -1 do
                local pos = utf8.offset(s, i)
                if pos then
                    return s:sub(1, pos - 1) .. "…"
                end
            end
        end
    end
    local maxBytes = maxChars * 3
    if #s > maxBytes then
        return s:sub(1, maxBytes - 1) .. "…"
    end
    return s
end

local function intervalMs()
    local n = tonumber(noctalia.getConfig("interval_ms"))
    if n == nil or n < 500 then
        n = 2000
    end
    if n > 60000 then
        n = 60000
    end
    return math.floor(n)
end

local appliedInterval = nil
local function applyInterval()
    local ms = intervalMs()
    if ms ~= appliedInterval then
        appliedInterval = ms
        noctalia.setUpdateInterval(ms)
    end
end

local function poll()
    noctalia.runAsync({ "octl", "query", "snaps", "--json" }, function(result)
        local snap = { online = false, counts = { busy = 0, permission = 0, error = 0, retry = 0, idle = 0 }, sessions = {} }
        if result.exitCode == 0 and result.stdout ~= nil and #result.stdout > 0 then
            local ok, data = pcall(noctalia.json.decode, result.stdout)
            if ok and type(data) == "table" and type(data.states) == "table" then
                snap.online = true
                local c = snap.counts
                for _, st in ipairs(data.states) do
                    local status = tostring(st.status or "UNKNOWN")
                    if status ~= "ARCHIVED" then
                        if status == "BUSY" then
                            c.busy = c.busy + 1
                        elseif status == "PERMISSION" then
                            c.permission = c.permission + 1
                        elseif status == "ERROR" then
                            c.error = c.error + 1
                        elseif status == "RETRY" then
                            c.retry = c.retry + 1
                        else
                            c.idle = c.idle + 1
                        end
                        table.insert(snap.sessions, {
                            sessionId = tostring(st.sessionId or ""),
                            status = status,
                            title = truncate(st.title, MAX_TITLE_CHARS),
                            -- What needs the user's eye: the pending command on a
                            -- permission prompt, the question being asked, or the
                            -- error message.
                            detail = truncate(st.permTitle or st.questionText or st.errorMsg, MAX_TITLE_CHARS),
                        })
                    end
                end
                table.sort(snap.sessions, function(a, b)
                    local pa = PRIORITY[a.status] or 9
                    local pb = PRIORITY[b.status] or 9
                    if pa ~= pb then
                        return pa < pb
                    end
                    return a.title < b.title
                end)
            end
        end
        noctalia.state.set("snap", snap)
    end, 8000)
end

applyInterval()
poll()

-- IPC probe: `noctalia msg plugin tomaswade/octl-agents:watcher all dump`
-- dumps the current snapshot as JSON (returned where supported, and written to
-- /tmp/opencode/octl-agents-dump.json) so the aggregation can be inspected
-- without looking at the bar.
local function jsonEscape(s)
    s = tostring(s or "")
    s = s:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n")
    return s
end

local function serializeSnapshot(snap)
    if snap == nil then
        return "null"
    end
    local c = snap.counts or {}
    local rows = {}
    for _, s in ipairs(snap.sessions or {}) do
        table.insert(rows, string.format(
            '{"status":"%s","title":"%s","detail":"%s"}',
            jsonEscape(s.status), jsonEscape(s.title), jsonEscape(s.detail)))
    end
    return string.format(
        '{"online":%s,"counts":{"busy":%d,"permission":%d,"error":%d,"retry":%d,"idle":%d},"sessions":[%s]}',
        tostring(snap.online == true),
        c.busy or 0, c.permission or 0, c.error or 0, c.retry or 0, c.idle or 0,
        table.concat(rows, ","))
end

function onIpc(event)
    if event == "dump" then
        local s = serializeSnapshot(noctalia.state.get("snap"))
        noctalia.writeFile("/tmp/opencode/octl-agents-dump.json", s)
        return s
    end
end

function update()
    applyInterval()
    poll()
end

function onConfigChanged()
    applyInterval()
    poll()
end
