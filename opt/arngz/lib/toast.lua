-- toast.lua: arngz's toasts, Starting, Running and Finished (ST589246c, WP
-- eae7633d). The design is that work package's body, and the points it hears
-- are the thread's progress.md, agreed between the run log (WP 53ef07aa) and
-- this module.
--
-- The engine emits each progress point once, writes it to the run log, and
-- hands the same name and fields to T.point(name, fields) (progress.md, rule
-- 5). apply's toast reads Starting while the engine reads the screens, then
-- Running..., rewritten in place as each wait and each step begins, then
-- Finished, which says what happened and stays up longer. discover gets its
-- Finished alone: it answers inside one IPC call, and Hammerspoon draws
-- nothing until that call has returned. Every other verb gets nothing.
--
-- PURE, THEN IMPURE. What a toast says, where it sits, how long it stays and
-- when it hides are pure functions of the points heard: T.cut, T.wrap,
-- T.app_name, T.linger, T.layout, T.hides and T.on_point, which also keeps
-- the runs. T.point is the thin coordinator over hs.canvas and hs.timer.
-- toast_test.lua drives both under plain Lua, the coordinator through an
-- injected hs.
--
-- NOTHING AT FILE SCOPE TOUCHES hs. Each reference resolves against the
-- global at call time, so a fake assigned to _G.hs is what this module sees,
-- as in engine_test.lua.
--
-- IT NEVER PRINTS. Hammerspoon sends every print to every registered hs
-- client, and a client arngz has killed raises "ipc port is no longer valid
-- (early)" until it is pruned (dc's log read of 23 Nov 2026, F3). So a failure
-- is raised instead, for the engine's catch to log (progress.md, rule 6), and
-- each hs module is reached through require (hs_module, below), never through
-- hs's own lazy loader, which prints "-- Loading extension" the first time a
-- module is touched (extensions/hs/_coresetup.lua).

local T = {}

-- How a toast reads and how long it stays (the design, "How it shows").
T.MAX_LINE = 90     -- characters in a line, the rest cut to "..."
T.LONG_LINES = 2    -- lines a refusal, a failure or a fix may take
T.LINGER_CLEAN = 5  -- seconds Finished stays after a clean run
T.LINGER_OTHER = 15 -- seconds it stays after any other outcome
T.LIFETIME = 120    -- seconds a toast lasts with no point heard
T.HANDS_OFF = "Hands off the mouse and keyboard until it finishes"
T.LOG_LINE = "arngz log has the rest"

-- How it looks: hs.alert's look, smaller.
T.TEXT_SIZE = 15
T.PADDING = 12     -- points between the panel's edge and its text
T.MARGIN = 24      -- points between the panel and the visible frame's bottom
T.GAP = 8          -- points between the running toast and a notice above it
T.MAX_WIDTH = 0.6  -- of the display's visible width
T.RADIUS = 10
T.FADE_IN = 0.15
T.FADE_OUT = 0.3

-- The strip below a window's top edge that holds its title bar, and with it
-- every point a move may grab (P.grab_candidates: the traffic lights' centre
-- line). A toolbar window's bar is the tallest, about 52 points.
T.TITLE_STRIP = 60

-- ---------------------------------------------------------------- the words

local function int(n)
  return string.format("%d", math.floor(n))
end

local function plural(n, one)
  return int(n) .. " " .. (n == 1 and one or (one .. "s"))
end

-- s cut to at most `max` bytes, ending "..." when it was cut, and never inside
-- a UTF-8 character: a byte from 0x80 to 0xBF continues one, so the cut backs
-- off over any that would follow it.
function T.cut(s, max)
  s = tostring(s)
  max = max or T.MAX_LINE
  if #s <= max then return s end
  local stop = math.max(max - 3, 0)
  while stop > 0 do
    local b = s:byte(stop + 1)
    if not (b and b >= 0x80 and b < 0xC0) then break end
    stop = stop - 1
  end
  return s:sub(1, stop) .. "..."
end

-- s as at most `count` lines of at most `max` bytes, broken between words. The
-- last line takes whatever is left over, and is cut.
function T.wrap(s, max, count)
  max, count = max or T.MAX_LINE, count or T.LONG_LINES
  local lines, line = {}, nil
  for word in tostring(s):gmatch("%S+") do
    if line == nil then
      line = word
    elseif #line + 1 + #word <= max then
      line = line .. " " .. word
    else
      lines[#lines + 1] = line
      line = word
    end
  end
  if line ~= nil then lines[#lines + 1] = line end
  if #lines > count then
    local rest = table.concat(lines, " ", count)
    for i = #lines, count, -1 do lines[i] = nil end
    lines[count] = rest
  end
  for i, l in ipairs(lines) do lines[i] = T.cut(l, max) end
  return lines
end

-- An app as a person reads it: a bundle id (dotted, with no space) by the
-- display name name_of finds for it, anything else as it is given. Never a
-- window title, which can carry a mail subject or a file name onto a screen
-- anyone can see.
function T.app_name(app, name_of)
  if type(app) ~= "string" or app == "" then return nil end
  if name_of and app:find("%.") and not app:find("%s") then
    local name = name_of(app)
    if type(name) == "string" and name ~= "" then return name end
  end
  return app
end

-- How long Finished stays: briefly after a clean run, longer when there is
-- something to read.
function T.linger(outcome)
  if outcome == "done" then return T.LINGER_CLEAN end
  return T.LINGER_OTHER
end

local function header(run)
  if type(run.desk) == "string" and run.desk ~= "" then return T.cut("arngz: " .. run.desk) end
  if run.verb == "discover" then return "arngz: Save Desk" end
  return "arngz"
end

local function headed(run, body)
  local lines = { header(run) }
  for _, line in ipairs(body) do lines[#lines + 1] = line end
  return lines
end

local function add_wrapped(lines, text)
  for _, line in ipairs(T.wrap(text)) do lines[#lines + 1] = line end
  return lines
end

-- A wait, by what it waits for (progress.md's `for`).
local WAITING = {
  ["new desktops"] = "waiting for macOS to record the new desktops",
  ["launched apps"] = "waiting for launched apps",
  ["unseen windows"] = "waiting for windows to show",
}

local function waiting_line(f)
  local what = WAITING[f["for"]] or ("waiting for " .. tostring(f["for"]))
  local longest = type(f.seconds) == "number" and string.format(" (up to %g s)", f.seconds) or ""
  return "Running... " .. what .. longest
end

local function on_display(f)
  if type(f.display) == "string" and f.display ~= "" then return " on " .. f.display end
  return ""
end

local function desktop(f)
  if type(f.desktop) == "number" then return "desktop " .. int(f.desktop) end
  return nil
end

-- A step, by its kind (progress.md: create, launch, move or place).
local STEP = {
  create = function(f)
    return "adding " .. (desktop(f) or "a desktop") .. on_display(f)
  end,
  launch = function(_, app)
    return "launching " .. (app or "an app")
  end,
  move = function(f, app)
    local to = desktop(f)
    return "moving " .. (app or "a window") .. (to and (" to " .. to) or "") .. on_display(f)
  end,
  place = function(f, app)
    return "placing " .. (app or "a window") .. on_display(f)
  end,
  recheck = function(_, app)
    return "checking " .. (app and (app .. "'s") or "a window's") .. " size"
  end,
}

local function step_line(f, name_of)
  local app = T.app_name(f.app, name_of)
  local say = STEP[f.kind]
  local what = say and say(f, app) or (tostring(f.kind) .. (app and (" " .. app) or ""))
  local count = ""
  if type(f.i) == "number" and type(f.n) == "number" then count = int(f.i) .. " of " .. int(f.n) .. ": " end
  return "Running... " .. count .. what
end

-- The counts a Finished line names, each only when it is not zero, in the
-- order a person reads a run: what it did, then what it could not.
local COUNTS = {
  { "placed", "placed" },
  { "in_place", "already in place" },
  { "unseen", "not found" },
  { "skipped", "skipped" },
  { "failed", "failed" },
}

local function counts(f)
  local parts = {}
  for _, c in ipairs(COUNTS) do
    local n = f[c[1]]
    if type(n) == "number" and n > 0 then parts[#parts + 1] = int(n) .. " " .. c[2] end
  end
  if type(f.created) == "number" and f.created > 0 then parts[#parts + 1] = plural(f.created, "desktop") .. " added" end
  return parts
end

local function took(f)
  if type(f.seconds) == "number" then return string.format(" in %.1f s", f.seconds) end
  return ""
end

local function said(f)
  if f.first == nil or f.first == "" then return "no reason was given" end
  return tostring(f.first)
end

local function refused(f, nothing)
  local lines = add_wrapped({}, "Refused, nothing " .. nothing .. ": " .. said(f))
  if type(f.fix) == "string" and f.fix ~= "" then add_wrapped(lines, "Fix: " .. f.fix) end
  return lines
end

local function failed(run, f)
  local head = "Failed"
  local stepped = type(run.i) == "number" and type(run.n) == "number"
  if stepped then head = head .. " at step " .. int(run.i) .. " of " .. int(run.n) end
  if type(f.seconds) == "number" then head = head .. (stepped and ", " or " ") .. string.format("after %.1f s", f.seconds) end
  local lines = add_wrapped({}, head .. ": " .. said(f))
  lines[#lines + 1] = T.LOG_LINE
  return lines
end

-- apply's Finished, by the point's outcome (progress.md: done, partly,
-- refused or failed).
local APPLY_FINISHED = {
  done = function(_, f)
    local parts = counts(f)
    local summary = table.concat(parts, ", ")
    if #parts == 0 then
      summary = "nothing to do"
    elseif #parts == 1 and type(f.in_place) == "number" and f.in_place > 0 then
      summary = "all " .. int(f.in_place) .. " already in place"
    end
    return { T.cut("Finished" .. took(f) .. ": " .. summary) }
  end,
  partly = function(_, f)
    local parts = counts(f)
    local lines = { T.cut("Finished" .. took(f) .. " with problems" .. (#parts > 0 and (": " .. table.concat(parts, ", ")) or "")) }
    if f.first ~= nil and f.first ~= "" then add_wrapped(lines, tostring(f.first)) end
    lines[#lines + 1] = T.LOG_LINE
    return lines
  end,
  refused = function(_, f) return refused(f, "moved") end,
  failed = failed,
}

local function what_was_read(run)
  local o = run.observed or {}
  local parts = {}
  for _, c in ipairs({ { "displays", "display" }, { "desktops", "desktop" }, { "windows", "window" } }) do
    if type(o[c[1]]) == "number" then parts[#parts + 1] = plural(o[c[1]], c[2]) end
  end
  return parts
end

-- discover's Finished. The CLI writes the desk file once the engine has
-- answered, so this says what was read; a save that then fails is the CLI's,
-- and Menuz's notice shows it.
local DISCOVER_FINISHED = {
  done = function(run, f)
    local parts = what_was_read(run)
    return { T.cut("Read the screens" .. took(f) .. (#parts > 0 and (": " .. table.concat(parts, ", ")) or "")) }
  end,
  refused = function(_, f) return refused(f, "saved") end,
  failed = failed,
}

local FINISHED = { apply = APPLY_FINISHED, discover = DISCOVER_FINISHED }

local function finished_lines(run, f)
  if run.slot == "notice" and run.verb == "apply" and f.outcome == "refused"
    and type(run.behind) == "string" and run.behind ~= "" then
    return { T.cut("Refused: " .. run.behind .. " is still being arranged") }
  end
  local say = (FINISHED[run.verb] or {})[f.outcome]
  if say then return say(run, f) end
  return { T.cut("Finished" .. took(f) .. " (" .. tostring(f.outcome) .. ")") }
end

-- ---------------------------------------------------------------- where it sits

-- Where a toast of `size` (its text's w and h) sits on a display whose visible
-- frame is `screen`: centred, a margin above the frame's bottom edge, or just
-- above `under`, the running toast, when it is a notice. arngz grabs a window
-- by its title bar, at its top, so the bottom band is where a grab is least
-- likely; T.hides covers the rest.
function T.layout(size, screen, under)
  local w = math.min(math.ceil(size.w) + 2 * T.PADDING, math.floor(screen.w * T.MAX_WIDTH))
  local h = math.ceil(size.h) + 2 * T.PADDING
  local bottom = under and (under.y - T.GAP) or (screen.y + screen.h - T.MARGIN)
  return { x = math.floor(screen.x + (screen.w - w) / 2), y = bottom - h, w = w, h = h }
end

-- Whether a toast at `frame` would cover the title bar of the window a move
-- step is about to grab: the window's frame now (x, y, w, carried by the
-- step, progress.md), down to T.TITLE_STRIP points below its top. grab_point's
-- hit test asks Accessibility what is under the point (arngz.lua), and a
-- Hammerspoon canvas may be what it finds even though it takes no click. Only
-- a move grabs. The carry after a drag needs nothing: P.drop_point lets go
-- with the window's top left 80 points into the target's visible frame, at
-- the top of that display.
function T.hides(frame, f)
  if type(frame) ~= "table" or type(f) ~= "table" or f.kind ~= "move" then return false end
  local x, y, w = f.x, f.y, f.w
  if type(x) ~= "number" or type(y) ~= "number" or type(w) ~= "number" then return false end
  return frame.x < x + w and x < frame.x + frame.w and frame.y < y + T.TITLE_STRIP and y < frame.y + frame.h
end

-- ---------------------------------------------------------------- the runs

-- The verbs a toast is drawn for (progress.md, rule 9): apply in full, and
-- discover at its finish.
local SHOWN = { apply = true, discover = true }

-- What each point does to the toasts, given the state they share across
-- calls, st: the runs heard by id, and live, the apply being shown. Each
-- returns a plan for T.point to draw, { slot, lines, step, linger }, or nil
-- when nothing on screen changes.
local ON = {}

-- A run that starts while an apply is shown is a notice, in a small toast of
-- its own above the running one: a second apply, which the engine refuses
-- (progress.md, rule 3), or a discover.
function ON.start(st, f)
  if not SHOWN[f.verb] then return nil end
  local live = st.live and st.runs[st.live]
  local run = { verb = f.verb, desk = f.desk, slot = live and "notice" or "main", behind = live and live.desk or nil }
  st.runs[f.run] = run
  if f.verb ~= "apply" or run.slot ~= "main" then return nil end
  st.live = f.run
  return { slot = "main", lines = headed(run, { "Starting: reading the screens and windows" }) }
end

function ON.observed(st, f)
  local run = st.runs[f.run]
  if run then run.observed = { displays = f.displays, desktops = f.desktops, windows = f.windows } end
  return nil
end

-- planned leaves Starting as it is: what hv needs next is a wait, a step or
-- Finished, and a refused plan comes as finished.
function ON.planned()
  return nil
end

-- An apply heard waiting or stepping is running. One that started as a notice
-- is shown in its place: the engine runs one apply at a time, so the apply
-- that looked live has stopped without a finished point.
local function running(st, id)
  local run = st.runs[id]
  if not run or run.verb ~= "apply" then return nil end
  if run.slot ~= "main" then
    if st.live and st.live ~= id then st.runs[st.live] = nil end
    run.slot, run.behind, st.live = "main", nil, id
  end
  return run
end

function ON.waiting(st, f)
  local run = running(st, f.run)
  if not run then return nil end
  local body = { T.cut(waiting_line(f)) }
  if run.stepped then body[#body + 1] = T.HANDS_OFF end
  return { slot = "main", lines = headed(run, body) }
end

function ON.step(st, f, name_of)
  local run = running(st, f.run)
  if not run then return nil end
  run.stepped, run.i, run.n = true, f.i, f.n
  return { slot = "main", lines = headed(run, { T.cut(step_line(f, name_of)), T.HANDS_OFF }), step = f }
end

function ON.finished(st, f)
  local run = st.runs[f.run]
  if not run then return nil end
  st.runs[f.run] = nil
  if st.live == f.run then st.live = nil end
  return { slot = run.slot, lines = headed(run, finished_lines(run, f)), linger = T.linger(f.outcome) }
end

-- What a point does, as ON says, given st, and name_of to name an app by its
-- bundle id. Every point progress.md names is in ON, the ones that draw
-- nothing included. A point it does not name, or one with no fields or no
-- run, breaks the contract, so it is raised: the engine and this module load
-- from one directory in one call, so there is no other version to allow for,
-- and a misspelt finished would otherwise leave the toast at Running.
function T.on_point(st, name, f, name_of)
  local on = ON[name]
  if not on then error("progress.md has no point named " .. tostring(name), 0) end
  if type(f) ~= "table" then error("the " .. tostring(name) .. " point carries no fields", 0) end
  if f.run == nil then error("the " .. tostring(name) .. " point carries no run, which progress.md gives every point", 0) end
  return on(st, f, name_of)
end

-- ---------------------------------------------------------------- drawing

-- The state the toasts share across IPC calls. dofile makes this module anew
-- at every call (D20), so it lives in one global, as arngz_running and
-- arngz_timer do in arngz.lua: the runs heard, the apply being shown, and
-- each slot's canvas and timers, which the global also keeps from being
-- collected before they fire.
local function shared()
  local st = rawget(_G, "arngz_toast")
  if type(st) ~= "table" then
    st = { runs = {}, slots = {} }
    rawset(_G, "arngz_toast", st)
  end
  return st
end

-- An hs module, through require. hs's lazy loader prints the first time it is
-- asked for a module (the header), and require loads the same module without
-- that line. rawget finds one already loaded, or the fake a test assigned.
local function hs_module(name)
  return rawget(hs, name) or require("hs." .. name)
end

local function stop(timer)
  if timer then timer:stop() end
end

local function primary_frame()
  local f = hs_module("screen").primaryScreen():frame()
  return { x = f.x, y = f.y, w = f.w, h = f.h }
end

-- A slot's canvas: hs.alert's look; no mouse callback, so a click goes to the
-- window under it and Hammerspoon is never activated; at the status level,
-- above app windows and the Dock and below menus; on every desktop, and left
-- alone by Mission Control, so it stays in view while the engine switches a
-- display's desktop.
local function new_canvas()
  local canvas = hs_module("canvas")
  local c = canvas.new({ x = 0, y = 0, w = 1, h = 1 })
  c:appendElements(
    { type = "rectangle", action = "strokeAndFill", fillColor = { white = 0, alpha = 0.78 },
      strokeColor = { white = 1, alpha = 0.8 }, strokeWidth = 1,
      roundedRectRadii = { xRadius = T.RADIUS, yRadius = T.RADIUS } },
    { type = "text", text = "", textSize = T.TEXT_SIZE, textColor = { white = 1 }, textLineBreak = "truncateTail" })
  c:level(canvas.windowLevels.status)
  c:behaviorAsLabels({ "canJoinAllSpaces", "stationary" })
  return c
end

-- A slot's toast taken off the screen, its timers stopped; the main slot's
-- going also forgets the apply it showed.
local function remove(st, name)
  local slot = st.slots[name]
  if not slot then return end
  st.slots[name] = nil
  stop(slot.linger)
  stop(slot.life)
  slot.canvas:delete(T.FADE_OUT)
  if name == "main" and st.live then
    st.runs[st.live] = nil
    st.live = nil
  end
end

-- A timer's callback, which takes a slot's toast down. It runs after the IPC
-- call that armed it has returned, so neither T.point's boundary nor the
-- engine's catch is on the stack: what fails is kept on the shared state,
-- never printed, and the next point raises it (T.point).
local function take_down(st, name)
  return function()
    local ok, err = pcall(remove, st, name)
    if not ok then st.late = "taking the " .. name .. " toast down: " .. tostring(err) end
  end
end

local function place(slot, frame)
  slot.frame = frame
  slot.canvas:frame(frame)
  slot.canvas:elementAttribute(2, "frame",
    { x = T.PADDING, y = T.PADDING, w = frame.w - 2 * T.PADDING, h = frame.h - 2 * T.PADDING })
end

-- Draw a plan: the slot's text rewritten in place and the toast sized to it; a
-- notice kept just above the running toast; every toast hidden that would
-- cover the title bar a move is about to grab, and shown again otherwise; the
-- slot's life renewed, and Finished given its linger.
local function draw(st, plan)
  local slot = st.slots[plan.slot]
  if not slot then
    slot = { canvas = new_canvas(), screen = primary_frame() }
    st.slots[plan.slot] = slot
  end
  stop(slot.linger)
  slot.linger = nil
  local text = table.concat(plan.lines, "\n")
  slot.canvas:elementAttribute(2, "text", text)
  slot.size = slot.canvas:minimumTextSize(2, text)
  local main, notice = st.slots.main, st.slots.notice
  place(slot, T.layout(slot.size, slot.screen, plan.slot == "notice" and main and main.frame or nil))
  if plan.slot == "main" and notice then place(notice, T.layout(notice.size, notice.screen, slot.frame)) end
  for _, s in pairs(st.slots) do
    local covers = T.hides(s.frame, plan.step)
    if covers and s.shown then
      s.canvas:hide()
      s.shown = false
    elseif not covers and not s.shown then
      s.canvas:show(s.drawn and 0 or T.FADE_IN)
      s.shown, s.drawn = true, true
    end
  end
  local timer = hs_module("timer")
  stop(slot.life)
  slot.life = timer.doAfter(T.LIFETIME, take_down(st, plan.slot))
  if plan.linger then slot.linger = timer.doAfter(plan.linger, take_down(st, plan.slot)) end
end

local function display_name(id)
  return hs_module("application").nameForBundleID(id)
end

-- The hook the engine calls at each progress point (progress.md, rule 5).
-- Whatever fails, from a point that breaks the contract to a canvas
-- Hammerspoon could not draw, is raised with the point's name for the
-- engine's catch to log and return once in the response (rule 6). A failure a
-- timer kept since the last point is raised too, once this point is drawn.
function T.point(name, fields)
  local ok, err = pcall(function()
    local st = shared()
    local plan = T.on_point(st, name, fields, display_name)
    if plan then draw(st, plan) end
    local late = st.late
    if late then
      st.late = nil
      error("earlier, " .. late, 0)
    end
  end)
  if not ok then error("arngz toast: the " .. tostring(name) .. " point: " .. tostring(err), 0) end
end

return T
