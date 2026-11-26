-- log.lua: arngz's run log, the engine's side (ST589246c, WP 53ef07aa).
--
-- Every run appends what it saw, planned, did and read back to the file the
-- CLI names in the request, ~/.local/state/arngz/arngz.log, one record per
-- line:
--
--   <time> <run> <source> <event> <text>
--
-- `time` is UTC to the millisecond, `run` the CLI's run id ("-" for the
-- display watcher), `source` is engine or displays (the CLI writes its own
-- records as cli), and `event` one fixed word per kind of record, so grep can
-- pick out one kind.
--
-- EVERYTHING HERE IS PURE but L.append, the one function that writes. The
-- formatters turn what the engine read into lines and decide nothing, so they
-- are tested under plain Lua (log_test.lua) with no Hammerspoon. Which list in
-- com.apple.spaces is a screen's own is WP 93ea7f8a's to settle, from this
-- log: here every list is named as macOS names it.

local L = {}

-- The most text one line carries. A longer record is split across lines with
-- the same event, so no line passes 1 KB, and a line is always written whole.
L.MAX_TEXT = 900

local function round(v)
  return math.floor((tonumber(v) or 0) + 0.5)
end

-- Text on one line: a control character (a newline in a window's title, a tab
-- in an error) becomes a space, so a record is always one line.
local function flat(text)
  return (tostring(text):gsub("%c", " "))
end

-- An epoch time in seconds, with its fraction, as UTC to the millisecond.
function L.stamp(t)
  local whole = math.floor(t)
  local ms = math.floor((t - whole) * 1000 + 0.5)
  if ms >= 1000 then whole, ms = whole + 1, ms - 1000 end
  return os.date("!%Y-%m-%dT%H:%M:%S", whole) .. string.format(".%03dZ", ms)
end

function L.record(stamp, run, source, event, text)
  return table.concat({ stamp, tostring(run or "-"), source, event, flat(text) }, " ")
end

-- How many of TEXT's first N bytes can be kept without splitting a UTF-8
-- character: N, less any bytes of a character that runs past it. A window
-- title is UTF-8, and a line cut inside a character reads as binary to grep.
local function whole_chars(text, n)
  while n > 0 do
    local next_byte = text:byte(n + 1)
    if not next_byte or next_byte < 128 or next_byte >= 192 then break end
    n = n - 1
  end
  return n
end

-- TEXT in pieces of at most MAX bytes, each broken at a space where there is
-- one, so a long record reads on as the next line, and never inside a
-- character.
function L.split(text, max)
  text = flat(text)
  max = max or L.MAX_TEXT
  if #text <= max then return { text } end
  local out, rest = {}, text
  while #rest > max do
    local cut = rest:sub(1, max):match("^.*() ")
    if not cut or cut <= 1 then cut = math.max(whole_chars(rest, max), 1) + 1 end
    out[#out + 1] = rest:sub(1, cut - 1)
    rest = rest:sub(cut):gsub("^ +", "")
  end
  if #rest > 0 then out[#out + 1] = rest end
  return out
end

local function ids(list)
  local out = {}
  for i, id in ipairs(list or {}) do out[i] = tostring(id) end
  return table.concat(out, " ")
end
L.ids = ids

local function frame_text(r)
  if type(r) ~= "table" then return "?" end
  return string.format("%d,%d %dx%d", round(r.x), round(r.y), round(r.w), round(r.h))
end
L.frame_text = frame_text

local function quoted(text, most)
  text = flat(text or "")
  if #text > most then text = text:sub(1, whole_chars(text, most)) .. "..." end
  return '"' .. text .. '"'
end

-- A value read, or "unread: <why>" when it could not be, as every other
-- error in the log is said.
local function read_or(value, why)
  if value == nil then return "unread: " .. tostring(why or "nothing came back") end
  return tostring(value)
end

-- com.apple.spaces' Monitors as plain lists: each entry's Display Identifier
-- as macOS writes it ("Main", or a display's UUID), its desktops in order, its
-- current desktop, and whether it is only a Collapsed Space, as macOS keeps
-- for a display no longer attached.
function L.recorded(monitors)
  local out = {}
  for _, m in ipairs(monitors or {}) do
    local spaces = {}
    for _, sp in ipairs(m.Spaces or {}) do spaces[#spaces + 1] = sp.ManagedSpaceID end
    local current = type(m["Current Space"]) == "table" and m["Current Space"].ManagedSpaceID or nil
    out[#out + 1] = {
      display = tostring(m["Display Identifier"] or "?"),
      spaces = spaces,
      current = current,
      collapsed = m["Collapsed Space"] ~= nil and #spaces == 0,
    }
  end
  return out
end

-- Where the record files each of a screen's live desktops: one group per
-- list, in the order its first desktop appears live, holding the live ids it
-- files, and "none" for an id no list holds. A desktop on two lists is filed
-- under the first.
function L.filed(live, recorded)
  local holder = {}
  for _, r in ipairs(recorded or {}) do
    for _, id in ipairs(r.spaces or {}) do
      if holder[id] == nil then holder[id] = r.display end
    end
  end
  local groups, at = {}, {}
  for _, id in ipairs(live or {}) do
    local d = holder[id] or "none"
    if not at[d] then
      groups[#groups + 1] = { display = d, ids = {} }
      at[d] = groups[#groups]
    end
    local g = at[d]
    g.ids[#g.ids + 1] = id
  end
  return groups
end

-- How many of a screen's live desktops are filed under a list other than the
-- one holding most of them, or under none: its visitors. A count for the log
-- and the observed point, never a decision.
function L.visitors(live, recorded)
  local most, total = 0, 0
  for _, g in ipairs(L.filed(live, recorded)) do
    total = total + #g.ids
    if g.display ~= "none" and #g.ids > most then most = #g.ids end
  end
  return total - most
end

-- The time since the last display change, from the watcher's STATE, at NOW.
function L.since(now, state)
  if type(state) ~= "table" then return "display changes are not watched yet" end
  if state.last_change then
    return string.format("last display change %d s ago (%s)", round(now - state.last_change), L.stamp(state.last_change))
  end
  return "no display change seen since the watcher started at " .. L.stamp(state.started or now)
end

-- The displays as a run saw them at LABEL, as { event, text } pairs: for each
-- screen its frame and the desktop it shows, its desktops live, where the
-- record files each, the order taken and where it came from, and the windows
-- arngz can name on each desktop; then every list com.apple.spaces holds, the
-- entries that hold no desktop ("Collapsed Space" alone) counted on one line
-- (WP 93ea7f8a). SINCE says when the displays last changed. WINDOWS false
-- leaves the windows out, as the watcher's snapshots do.
function L.world_pairs(world, label, since, windows)
  local out = {}
  local function add(event, text) out[#out + 1] = { event, text } end
  local screens = world.screens or {}
  local about = {}
  if world.macos then about[#about + 1] = "macOS " .. tostring(world.macos) end
  if world.hammerspoon then about[#about + 1] = "Hammerspoon " .. tostring(world.hammerspoon) end
  if world.accessibility ~= nil then about[#about + 1] = "Accessibility " .. tostring(world.accessibility) end
  add("displays", string.format("%s: %d display(s)%s%s", label, #screens,
    #about > 0 and ("; " .. table.concat(about, ", ")) or "", since and ("; " .. since) or ""))
  for _, s in ipairs(screens) do
    local u = tostring(s.uuid)
    add("screen", string.format("%s %s %s%s%s, showing %s", u, quoted(s.name, 60), frame_text(s.full_frame),
      s.position and (" " .. tostring(s.position)) or "", s.primary and ", primary" or "",
      read_or(s.active_space, s.active_error)))
    if s.live then
      add("live", u .. ": " .. ids(s.live))
    elseif s.spaces_error then
      add("live", u .. ": unread: " .. tostring(s.spaces_error))
    end
    local groups = {}
    for _, g in ipairs(L.filed(s.live, world.recorded)) do
      groups[#groups + 1] = ids(g.ids) .. " under " .. g.display
    end
    if #groups > 0 then add("filed", u .. ": " .. table.concat(groups, "; ")) end
    if s.spaces and #s.spaces > 0 then
      local taken = {}
      for i, sp in ipairs(s.spaces) do taken[i] = sp.id end
      add("order", string.format("%s: %s (%s%s)", u, ids(taken), tostring(s.order_source),
        s.order_note and ("; " .. tostring(s.order_note)) or ""))
    end
    if windows ~= false then
      for _, sp in ipairs(s.spaces or {}) do
        local names = {}
        for _, w in ipairs(sp.windows or {}) do
          if w.named then
            names[#names + 1] = string.format("%s %s %s %s", tostring(w.bundle), tostring(w.id), frame_text(w.frame),
              quoted(w.title, 40))
          end
        end
        add("windows", string.format("%s desktop %s (%s, %s): %s named of %s%s%s", u, tostring(sp.ordinal),
          tostring(sp.id), read_or(sp.type, sp.type_error), tostring(sp.named or 0), tostring(sp.window_ids or 0),
          sp.windows_error and ("; unread: " .. tostring(sp.windows_error)) or "",
          #names > 0 and (": " .. table.concat(names, "; ")) or ""))
      end
    end
  end
  local collapsed, under, per = 0, {}, {}
  for _, r in ipairs(world.recorded or {}) do
    if r.collapsed then
      collapsed = collapsed + 1
      if not per[r.display] then
        per[r.display] = 0
        under[#under + 1] = r.display
      end
      per[r.display] = per[r.display] + 1
    else
      add("record", string.format("%s: %s (current %s)", r.display, ids(r.spaces), tostring(r.current)))
    end
  end
  if collapsed > 0 then
    local each = {}
    for i, d in ipairs(under) do each[i] = string.format("%s x%d", d, per[d]) end
    add("record", string.format("collapsed: %d %s, under %s", collapsed, collapsed == 1 and "entry" or "entries",
      table.concat(each, ", ")))
  end
  if world.recorded_error then add("record", "unread: " .. tostring(world.recorded_error)) end
  return out
end

-- The observed point's fields (progress.md), from a world. `order` says where
-- the displays' desktop orders came from (WP 93ea7f8a): "record" when every
-- display's is com.apple.spaces', else how many are the live list's and how
-- many have none, their desktops unread, eg "of 3 displays: live on 1,
-- unread on 1"; "no displays" when there are none.
function L.observed_fields(world)
  local f = { displays = 0, desktops = 0, windows = 0, visitors = 0 }
  local from_live, unread = 0, 0
  for _, s in ipairs(world.screens or {}) do
    f.displays = f.displays + 1
    f.desktops = f.desktops + #(s.live or {})
    f.visitors = f.visitors + L.visitors(s.live, world.recorded)
    for _, sp in ipairs(s.spaces or {}) do f.windows = f.windows + (sp.named or 0) end
    if s.order_source == "live" then
      from_live = from_live + 1
    elseif s.order_source ~= "record" then
      unread = unread + 1
    end
  end
  -- The window list's read (WP 88504807): how many windows it frees, or why
  -- it could not be read.
  if world.free_error then
    f.window_list = "unread: " .. tostring(world.free_error)
  elseif world.free_windows then
    f.window_list = #world.free_windows .. " free"
  end
  local parts = {}
  if from_live > 0 then parts[#parts + 1] = "live on " .. from_live end
  if unread > 0 then parts[#parts + 1] = "unread on " .. unread end
  if f.displays == 0 then
    f.order = "no displays"
  elseif #parts == 0 then
    f.order = "record"
  else
    f.order = string.format("of %d displays: %s", f.displays, table.concat(parts, ", "))
  end
  return f
end

-- The plan as records: how many ops of each kind, then each line in diff's
-- own words (P.plan_report).
function L.plan_pairs(ops, lines)
  local counts, kinds = {}, {}
  for _, op in ipairs(ops or {}) do counts[op.op] = (counts[op.op] or 0) + 1 end
  for k, n in pairs(counts) do kinds[#kinds + 1] = tostring(k) .. " " .. n end
  table.sort(kinds)
  local out = { { "plan", string.format("%d op(s)%s", #(ops or {}), #kinds > 0 and (": " .. table.concat(kinds, ", ")) or "") } }
  for _, line in ipairs(lines or {}) do out[#out + 1] = { "plan", line } end
  return out
end

-- Which planned field counts each kind of op the engine executes: the
-- progress point's own words (progress.md). log_test ties it to the kinds the
-- engine runs, so a kind added there and not here goes red.
L.PLANNED_FIELD = { remove_space = "removes", create_space = "creates", move = "moves", place = "places",
  recheck = "places" }

-- The planned point's fields (progress.md), from the ops or a refusal. Every
-- field in L.PLANNED_FIELD is there, 0 when the plan has none of its kind.
function L.planned_fields(ops, refused)
  local f = {}
  local key = L.PLANNED_FIELD
  for _, field in pairs(key) do f[field] = 0 end
  local any = 0
  for _, op in ipairs(ops or {}) do
    if key[op.op] then
      f[key[op.op]] = f[key[op.op]] + 1
      any = any + 1
    end
  end
  f.nothing = refused == nil and any == 0
  if refused then f.refused = tostring(refused) end
  return f
end

-- What a readback holds, in words.
function L.readback_text(rb)
  if type(rb) ~= "table" then return "nothing" end
  local out = {}
  if rb.frame then out[#out + 1] = "frame " .. frame_text(rb.frame) end
  if rb.window_spaces then out[#out + 1] = "on " .. (#rb.window_spaces > 0 and ids(rb.window_spaces) or "no desktop") end
  if rb.shown ~= nil then out[#out + 1] = "screen shows " .. tostring(rb.shown) end
  if rb.listed_at_destination ~= nil then out[#out + 1] = "listed at the destination " .. tostring(rb.listed_at_destination) end
  if rb.listed_at_origin ~= nil then out[#out + 1] = "listed at the origin " .. tostring(rb.listed_at_origin) end
  if rb.user_spaces then out[#out + 1] = tostring(rb.user_spaces) .. " user desktops" end
  -- A removal's: the live list after it (ST6d8eed9 WP 88504807).
  if rb.live then out[#out + 1] = "desktops live " .. ids(rb.live) end
  for _, e in ipairs(rb.errors or {}) do out[#out + 1] = "unread: " .. tostring(e) end
  return #out > 0 and table.concat(out, ", ") or "nothing"
end

-- The full-screen windows a move with no route would have passed, with their
-- titles, which go to the log and never to the toast (STca1b7f9 WP4).
local function passed_text(passed)
  local out = {}
  for _, w in ipairs(passed or {}) do
    if w.app then
      out[#out + 1] = string.format("%s %s on %s", tostring(w.app), quoted(w.title, 40), tostring(w.space))
    else
      out[#out + 1] = "a window arngz cannot name on " .. tostring(w.space)
    end
  end
  return table.concat(out, ", ")
end

-- One op's outcome: kind and path, the window's title where the op keeps it
-- for the log alone (issue I4eacd29), the status and reason the report has,
-- its fix as a refused plan's is written, the full-screen windows a move
-- could not pass, a note, what it read back, the desktops it created or
-- removed, and how long it took.
function L.result_text(op, r, ms)
  local parts = { string.format("%s %s", tostring(op.op), tostring(op.path or op.bundle or "")) }
  if op.title then parts[#parts + 1] = string.format("window %s %s", tostring(op.window), quoted(op.title, 60)) end
  parts[#parts + 1] = tostring(r.status) .. (r.reason and (": " .. tostring(r.reason)) or "")
  if r.fix then parts[#parts + 1] = "fix: " .. tostring(r.fix) end
  if r.passed and #r.passed > 0 then parts[#parts + 1] = "full screen: " .. passed_text(r.passed) end
  if r.note then parts[#parts + 1] = "note: " .. tostring(r.note) end
  if r.readback then parts[#parts + 1] = "read back: " .. L.readback_text(r.readback) end
  if r.created then parts[#parts + 1] = "created desktop " .. (#r.created > 0 and ids(r.created) or "none seen") end
  if r.removed then parts[#parts + 1] = "removed desktop " .. (#r.removed > 0 and ids(r.removed) or "none seen") end
  if ms then parts[#parts + 1] = string.format("%d ms", round(ms)) end
  return table.concat(parts, "; ")
end

-- A progress point as one record's text: its name, then its fields in name
-- order, so two runs' records compare line by line.
function L.point_text(name, fields)
  local keys = {}
  for k in pairs(fields or {}) do keys[#keys + 1] = tostring(k) end
  table.sort(keys)
  local parts = { tostring(name) }
  for _, k in ipairs(keys) do parts[#parts + 1] = k .. "=" .. tostring(fields[k]) end
  return table.concat(parts, " ")
end

-- Where an op's path points in the desk: the display's name and the
-- desktop's ordinal, from "displays[d].spaces[s]...", which counts from 0.
function L.path_place(desk, path)
  local d = tonumber(tostring(path or ""):match("^displays%[(%d+)%]"))
  local s = tonumber(tostring(path or ""):match("%.spaces%[(%d+)%]"))
  local display = d and type(desk) == "table" and desk.displays and desk.displays[d + 1]
  return display and display.name or (d and ("display " .. (d + 1))) or "", s and (s + 1) or 0
end

-- A step's kind in progress.md's words, where the op's own name is not them:
-- "create, remove, move, place or recheck" (ST6d8eed9 WP 88504807). The
-- toast keys its lines on these words.
L.STEP_KIND = { create_space = "create", remove_space = "remove" }

-- The step point's fields (progress.md) for OP, the I-th step of N on DESK.
-- FRAME is a move's window frame as read just now, or nil. VIA is the display
-- a move goes round through, by the desk's name for it or the screen's own
-- (STca1b7f9 WP3), or nil for a move that goes straight. A removal's desktop
-- is its ordinal when its step begins, which is the plan's: the plan removes
-- the later desktops first.
function L.step_fields(desk, op, i, n, frame, via)
  local display, desktop = L.path_place(desk, op.path)
  local f = { i = i, n = n, kind = L.STEP_KIND[op.op] or tostring(op.op), app = tostring(op.bundle or ""),
    display = display, desktop = op.ordinal or desktop }
  if type(frame) == "table" then f.x, f.y, f.w, f.h = frame.x, frame.y, frame.w, frame.h end
  if type(via) == "string" and via ~= "" then f.via = via end
  return f
end

-- Apply's report as records: each line, then the exit and the tally.
function L.report_pairs(lines, code, tally)
  local out = {}
  for _, line in ipairs(lines or {}) do out[#out + 1] = { "report", line } end
  out[#out + 1] = { "report", string.format("exit %s: %d placed, %d in place, %d failed, %d unseen, %d not running,"
    .. " %d desktop(s) created, %d removed", tostring(code), tally.placed, tally.in_place, tally.failed, tally.unseen,
    tally.not_running, tally.created, tally.removed or 0) }
  return out
end

-- The finished point's fields (progress.md) from a run's RESPONSE, whatever
-- it says. An apply's counts come from its report's tally; done when it
-- exited 0, partly when it exited 1 having placed something, failed when it
-- placed nothing. Every other verb is done when it answered ok. A refusal of
-- kind reload is a refusal: nothing changed (ST6d8eed9 WP a45b3aeb).
function L.finished_fields(response, seconds, log_path)
  local t = type(response.tally) == "table" and response.tally or {}
  local refusal = response.kind == "refused" or response.kind == "reload"
  local outcome
  if response.status ~= "ok" then
    outcome = refusal and "refused" or "failed"
  elseif response.verb == "apply" and response.exit == 1 then
    outcome = ((t.placed or 0) + (t.in_place or 0)) > 0 and "partly" or "failed"
  else
    outcome = "done"
  end
  local exit = response.exit
  if exit == nil then exit = response.status == "ok" and 0 or (refusal and 2 or 1) end
  return {
    outcome = outcome,
    exit = exit,
    -- Whether this answer asks the CLI to reload Hammerspoon's config and run
    -- the verb again: a refusal of kind reload, or an apply that ran and
    -- carries reload. The CLI acts after this point (ST6d8eed9 WP a45b3aeb).
    reload = response.kind == "reload" or (response.reload ~= nil and response.reload ~= false),
    -- How many times the run paused for the pointer (ST6d8eed9 WP 4cb617e2).
    paused = tonumber(response.paused) or 0,
    placed = t.placed or 0,
    in_place = t.in_place or 0,
    failed = t.failed or 0,
    unseen = t.unseen or 0,
    -- Entries whose app is not running, which apply never launches, and
    -- those apps' names as one string, absent when every app ran (ST6d8eed9
    -- WP 35219619).
    not_running = t.not_running or 0,
    not_running_apps = t.not_running_apps,
    created = t.created or 0,
    -- The desktops removed, and the user desktops the run leaves beyond the
    -- desk's count on the displays it matched, read from its last observe:
    -- absent when that read failed or the desk no longer matches the screens
    -- (ST6d8eed9 WP 88504807).
    removed = t.removed or 0,
    extra = tonumber(response.extra),
    -- The desktops apply showed to name windows on desktops not shown (the
    -- visit step, cc's visit-note).
    shown = tonumber(response.shown) or 0,
    seconds = seconds or 0,
    first = tostring(response.error or t.first or ""),
    -- What the entry `first` names was, in the tally's own keys ("failed" or
    -- "unseen": a not-running entry is uncounted, so never first), so the
    -- toast can label it; absent when first is a refusal's or a failed run's
    -- words (STca1b7f9 WP6, ic's words).
    first_outcome = response.error == nil and t.first_outcome or nil,
    -- A refusal's fix, or the first failure's, which the tally carries with
    -- `first` (STca1b7f9 WP4).
    fix = tostring(response.fix or (response.error == nil and t.fix) or ""),
    log = tostring(log_path or ""),
  }
end

-- A request's options in brief, for a run's start record.
function L.options_text(options)
  if type(options) ~= "table" then return "none" end
  local parts = {}
  -- may_reload and after_reload_of say whether the CLI lets the engine ask
  -- for a reload, and which run a retry after a reload follows (ST6d8eed9
  -- WP a45b3aeb).
  for _, k in ipairs({ "no_create", "grid", "name", "current", "may_reload", "after_reload_of" }) do
    if options[k] ~= nil and options[k] ~= false then parts[#parts + 1] = k .. "=" .. tostring(options[k]) end
  end
  for _, k in ipairs({ "map", "own_sizes", "desks" }) do
    local n = 0
    for _ in pairs(type(options[k]) == "table" and options[k] or {}) do n = n + 1 end
    if n > 0 then parts[#parts + 1] = k .. " " .. n end
  end
  return #parts > 0 and table.concat(parts, ", ") or "none"
end

-- THE ONE IMPURE FUNCTION. Each line is written whole, in one write: the file
-- is opened for append and closed again, so two writers never split a line
-- and no handle outlives the CLI's rotation. True, or nil and why.
function L.append(path, lines)
  local f, err = io.open(path, "a")
  if not f then return nil, tostring(err) end
  local ok, why = pcall(function()
    f:setvbuf("full", 65536)
    for _, line in ipairs(lines) do
      assert(f:write(line, "\n"))
      assert(f:flush())
    end
  end)
  f:close()
  if not ok then return nil, tostring(why) end
  return true
end

return L
