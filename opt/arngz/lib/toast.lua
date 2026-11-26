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
-- ST6d8eed9 adds what a toast says of an app that is not running (WP
-- 35219619), of a reload of Hammerspoon's config and the run again (WP
-- a45b3aeb), of a pause while the person has the pointer (WP 4cb617e2), and
-- of the extra empty desktops a run removes (WP 88504807).
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

-- A run that is the retry after a reload of Hammerspoon's config says so on
-- each of its toasts (progress.md's start after_reload_of; ST6d8eed9
-- AC-a45b3aeb.8). A long desk name is cut before it, never in it.
local AFTER_RELOAD = " (after a reload)"

local function header(run)
  local again = run.reloaded and AFTER_RELOAD or ""
  local head = "arngz"
  if type(run.desk) == "string" and run.desk ~= "" then
    head = "arngz: " .. run.desk
  elseif run.verb == "discover" then
    head = "arngz: Save Desk"
  end
  return T.cut(head, T.MAX_LINE - #again) .. again
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

-- A wait, by what it waits for (progress.md's `for`). "desktop changes" is the
-- wait after the desktops are removed, created, or both (ST6d8eed9 WP
-- 88504807).
local WAITING = {
  ["desktop changes"] = "waiting for macOS to record the desktop changes",
  ["unseen windows"] = "waiting for windows to show",
}

-- The wait that is a pause: the person took the pointer during a move, and
-- the move goes on once the pointer is still (progress.md's waiting `for` and
-- `still`; ST6d8eed9 AC-4cb617e2.6). Its line says Paused, not Running...,
-- in the words of what it waits for.
local PAUSE_FOR = "the pointer to be still"

local function waiting_line(f)
  local longest = type(f.seconds) == "number" and string.format(" (up to %g s)", f.seconds) or ""
  if f["for"] == PAUSE_FOR then
    local still = type(f.still) == "number" and string.format(" for %g s", f.still) or ""
    return "Paused: waiting for " .. PAUSE_FOR .. still .. longest
  end
  local what = WAITING[f["for"]] or ("waiting for " .. tostring(f["for"]))
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

-- A step, by its kind (progress.md: create, remove, move, place or recheck).
-- A removal's desktop is its ordinal when its step begins (ST6d8eed9 WP
-- 88504807).
local STEP = {
  create = function(f)
    return "adding " .. (desktop(f) or "a desktop") .. on_display(f)
  end,
  remove = function(f)
    local which = desktop(f)
    return "removing " .. (which and ("empty " .. which) or "an empty desktop") .. on_display(f)
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

-- A move that goes round through another display, past a full-screen space,
-- says so at the end of its line (progress.md's step `via`; STca1b7f9
-- AC-dca427e7.3). It is the one sign that the window is about to leave its
-- display, so the cut takes from the words before it, never from it.
local function round_through(f)
  if f.kind == "move" and type(f.via) == "string" and f.via ~= "" then return ", round through " .. f.via end
  return ""
end

local function step_line(f, name_of)
  local app = T.app_name(f.app, name_of)
  local say = STEP[f.kind]
  local what = say and say(f, app) or (tostring(f.kind) .. (app and (" " .. app) or ""))
  local count = ""
  if type(f.i) == "number" and type(f.n) == "number" then count = int(f.i) .. " of " .. int(f.n) .. ": " end
  local round = round_through(f)
  return T.cut("Running... " .. count .. what, T.MAX_LINE - #round) .. round
end

-- The counts a Finished line names, each only when it is not zero, in the
-- order a person reads a run: what it did, then what it could not. apply
-- never launches an app, so an entry whose app is not running is counted
-- here and counts against nothing (ST6d8eed9 WP 35219619).
local COUNTS = {
  { "placed", "placed" },
  { "in_place", "already in place" },
  { "unseen", "not found" },
  { "not_running", "not running" },
  { "failed", "failed" },
}

-- The counts, then the desktops removed and added, in the order the run makes
-- them, then the extra desktops it leaves (progress.md's finished removed and
-- extra; ST6d8eed9 WP 88504807), then the times the run paused for the
-- pointer (progress.md's finished paused; ST6d8eed9 AC-4cb617e2.6).
local function counts(f)
  local parts = {}
  for _, c in ipairs(COUNTS) do
    local n = f[c[1]]
    if type(n) == "number" and n > 0 then parts[#parts + 1] = int(n) .. " " .. c[2] end
  end
  if type(f.removed) == "number" and f.removed > 0 then parts[#parts + 1] = plural(f.removed, "desktop") .. " removed" end
  if type(f.created) == "number" and f.created > 0 then parts[#parts + 1] = plural(f.created, "desktop") .. " added" end
  if type(f.extra) == "number" and f.extra > 0 then
    parts[#parts + 1] = plural(f.extra, "extra desktop") .. " not removed"
  end
  if type(f.paused) == "number" and f.paused > 0 then parts[#parts + 1] = plural(f.paused, "pause") .. " for the pointer" end
  return parts
end

-- A Finished line: its head, then the counts, on as many lines as they take.
-- It breaks only between two counts, so no count is cut in two: a count's
-- own spaces are held as HELD while T.wrap breaks between words, then given
-- back. HELD is one byte, as a space is, so each line keeps its length. A
-- count fits on a line, so the lines never outnumber the counts and the head,
-- and no count is cut at the end either: a busy run that also removes, adds
-- and leaves desktops takes a third line (ST6d8eed9 WP 88504807).
local HELD = "\1"

local function counts_lines(head, parts)
  local held = {}
  for i, part in ipairs(parts) do held[i] = (part:gsub(" ", HELD)) end
  local lines = T.wrap(head .. table.concat(held, ", "), T.MAX_LINE, #parts + 1)
  for i, line in ipairs(lines) do lines[i] = (line:gsub(HELD, " ")) end
  return lines
end

-- What a first problem can have been (progress.md's finished first_outcome).
-- An entry whose app is not running counts against nothing, so it is never
-- the first problem.
local FIRST_OUTCOMES = { failed = true, unseen = true }

-- The label on a partly run's first problem: what it was, in COUNTS' own words,
-- so the label and the count can never disagree, and an unseen entry reads
-- "Not found:", never under "failed" (STca1b7f9 AC-322a6511.9). "" when the
-- point does not say, or says something toast.lua does not know.
local function first_label(f)
  if not FIRST_OUTCOMES[f.first_outcome] then return "" end
  for _, c in ipairs(COUNTS) do
    if c[1] == f.first_outcome then return c[2]:sub(1, 1):upper() .. c[2]:sub(2) .. ": " end
  end
  return ""
end

local function took(f)
  if type(f.seconds) == "number" then return string.format(" in %.1f s", f.seconds) end
  return ""
end

local function said(f)
  if f.first == nil or f.first == "" then return "no reason was given" end
  return tostring(f.first)
end

-- The fix a Finished names, under the words it fixes: a refusal's, or the
-- first failure's (progress.md's finished `fix`; STca1b7f9 AC-ad94d40b.2).
-- One rule for every outcome that can carry one.
local function add_fix(lines, f)
  if type(f.fix) == "string" and f.fix ~= "" then add_wrapped(lines, "Fix: " .. f.fix) end
  return lines
end

-- The apps that are not running, by name, on a line under the counts, since
-- "N not running" names none (progress.md's finished not_running_apps;
-- ST6d8eed9 AC-35219619.6). The engine gives them as one string, each app as
-- it read the name, else as the desk spells it.
local function add_not_running(lines, f)
  if type(f.not_running_apps) == "string" and f.not_running_apps ~= "" then
    add_wrapped(lines, "Not running: " .. f.not_running_apps)
  end
  return lines
end

local function refused(f, nothing)
  return add_fix(add_wrapped({}, "Refused, nothing " .. nothing .. ": " .. said(f)), f)
end

local function failed(run, f)
  local head = "Failed"
  local stepped = type(run.i) == "number" and type(run.n) == "number"
  if stepped then head = head .. " at step " .. int(run.i) .. " of " .. int(run.n) end
  if type(f.seconds) == "number" then head = head .. (stepped and ", " or " ") .. string.format("after %.1f s", f.seconds) end
  local lines = add_fix(add_wrapped({}, head .. ": " .. said(f)), f)
  lines[#lines + 1] = T.LOG_LINE
  return lines
end

-- apply's Finished, by the point's outcome (progress.md: done, partly,
-- refused or failed).
local APPLY_FINISHED = {
  done = function(_, f)
    local parts = counts(f)
    if #parts == 0 then
      parts = { "nothing to do" }
    elseif #parts == 1 and type(f.in_place) == "number" and f.in_place > 0 then
      parts = { "all " .. int(f.in_place) .. " already in place" }
    end
    return add_not_running(counts_lines("Finished" .. took(f) .. ": ", parts), f)
  end,
  partly = function(_, f)
    local parts = counts(f)
    local lines = counts_lines("Finished" .. took(f) .. " with problems" .. (#parts > 0 and ": " or ""), parts)
    add_not_running(lines, f)
    if f.first ~= nil and f.first ~= "" then add_wrapped(lines, first_label(f) .. tostring(f.first)) end
    add_fix(lines, f)
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

-- A Finished whose run asks the CLI to reload Hammerspoon's config and run
-- again (progress.md's finished reload; ST6d8eed9 AC-a45b3aeb.8) says what
-- comes next, whatever its outcome, and not its counts: the reload takes this
-- toast down, and the run again draws a toast of its own.
local RELOADING = "Reloading Hammerspoon, then running again: its window filter failed"

local function finished_lines(run, f)
  if f.reload == true then return { RELOADING } end
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
-- (progress.md, rule 3), or a discover. A run that carries after_reload_of is
-- the run again after a reload, under the same run id, in a fresh Lua state.
function ON.start(st, f)
  if not SHOWN[f.verb] then return nil end
  local live = st.live and st.runs[st.live]
  local run = { verb = f.verb, desk = f.desk, slot = live and "notice" or "main", behind = live and live.desk or nil,
    reloaded = f.after_reload_of ~= nil and f.after_reload_of ~= "" }
  st.runs[f.run] = run
  if f.verb ~= "apply" or run.slot ~= "main" then return nil end
  st.live = f.run
  local starting = run.reloaded and "Starting again" or "Starting"
  return { slot = "main", lines = headed(run, { starting .. ": reading the screens and windows" }) }
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

-- The visit step (cc's visit-note, 26 Nov 2026): before any change, apply
-- shows each desktop not shown that holds an unseen app's window, through
-- Mission Control. Its point is waiting with `for` FINDING_FOR, the
-- desktop's `place` and its `display`, and no seconds. Its line says which
-- desktop is shown, so the change of desktops does not read as a fault, and
-- Hands off is under it from the first, since Mission Control is on screen.
local FINDING_FOR = "finding windows"

local function finding_line(f)
  local which = type(f.place) == "number" and ("desktop " .. int(f.place)) or "a desktop"
  return "Running... finding windows: showing " .. which .. on_display(f)
end

function ON.waiting(st, f)
  local run = running(st, f.run)
  if not run then return nil end
  local finding = f["for"] == FINDING_FOR
  local body = { T.cut(finding and finding_line(f) or waiting_line(f)) }
  if run.stepped or finding then body[#body + 1] = T.HANDS_OFF end
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

-- ---------------------------------------------------------------- the marks

-- The start and end marks (hv decision 53, ic's marks-note of 26 Nov 2026).
-- hv's need: to know when arngz has the mouse and keyboard, and when it has
-- let go. The CLI makes them, with a sound of its own, through a short hs
-- call each: arngz.lua's M.mark, then T.mark. They are in a slot of their own,
-- "mark", apart from Starting, Running... and Finished, which stay as they
-- are. The start mark stays until the end mark takes its place, or for the
-- seconds the CLI gives it, so a CLI killed by SIGKILL leaves it only that
-- long. The end mark stays T.MARK_LINGER. "still" is the CLI's end when it
-- stopped waiting for an apply that is still at work: it stays for the
-- seconds given, and the engine's own finish ends it.
T.MARK_LINGER = 3    -- seconds the end mark stays
T.MARK_LINE = 36     -- characters in a mark's line
T.MARK_TEXT_SIZE = 13

local MARK_KINDS = { start = true, ["end"] = true, still = true }

-- Where a mark of `size` sits on a display whose visible frame is `screen`:
-- its bottom right, a margin in from the frame's right and bottom edges. Its
-- width is held to the band right of the widest work toast (T.MAX_WIDTH of
-- the width, centred), so the two never meet.
function T.mark_layout(size, screen)
  local band = math.floor(screen.w * (1 - T.MAX_WIDTH) / 2) - T.MARGIN
  local w = math.min(math.ceil(size.w) + 2 * T.PADDING, band)
  local h = math.ceil(size.h) + 2 * T.PADDING
  return { x = screen.x + screen.w - T.MARGIN - w, y = screen.y + screen.h - T.MARGIN - h, w = w, h = h }
end

-- The plan for a mark: its words on at most T.LONG_LINES lines of
-- T.MARK_LINE, its place, and how long it stays. A kind it does not know,
-- no words, or a start or still with no time to stay breaks the CLI's call,
-- so it is raised.
function T.on_mark(kind, words, seconds)
  if not MARK_KINDS[kind] then error("a mark is start, end or still, not " .. tostring(kind), 0) end
  if type(words) ~= "string" or words == "" then error("the " .. kind .. " mark has no words", 0) end
  local plan = { slot = "mark", lines = T.wrap(words, T.MARK_LINE, T.LONG_LINES), layout = T.mark_layout,
    text_size = T.MARK_TEXT_SIZE }
  if kind == "end" then
    plan.linger = T.MARK_LINGER
  else
    if type(seconds) ~= "number" or seconds <= 0 then
      error("the " .. kind .. " mark needs the seconds it may stay, not " .. tostring(seconds), 0)
    end
    plan.life = seconds
  end
  return plan
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
local function new_canvas(text_size)
  local canvas = hs_module("canvas")
  local c = canvas.new({ x = 0, y = 0, w = 1, h = 1 })
  c:appendElements(
    { type = "rectangle", action = "strokeAndFill", fillColor = { white = 0, alpha = 0.78 },
      strokeColor = { white = 1, alpha = 0.8 }, strokeWidth = 1,
      roundedRectRadii = { xRadius = T.RADIUS, yRadius = T.RADIUS } },
    { type = "text", text = "", textSize = text_size, textColor = { white = 1 }, textLineBreak = "truncateTail" })
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

-- Draw a plan: the slot's text rewritten in place and the toast sized to it,
-- where the plan's own layout puts it (a mark), else as T.layout does; a
-- notice kept just above the running toast; every toast hidden that would
-- cover the title bar a move is about to grab, and shown again otherwise; the
-- slot's life renewed, for the plan's own life or T.LIFETIME, and Finished
-- given its linger. A mark comes in a call of its own, between the work
-- points, so it keeps the grab the last work point named (st.step): a toast
-- hidden for a grab stays hidden, and the mark hides too.
local function draw(st, plan)
  local slot = st.slots[plan.slot]
  if not slot then
    slot = { canvas = new_canvas(plan.text_size or T.TEXT_SIZE), screen = primary_frame() }
    st.slots[plan.slot] = slot
  end
  stop(slot.linger)
  slot.linger = nil
  local text = table.concat(plan.lines, "\n")
  slot.canvas:elementAttribute(2, "text", text)
  slot.size = slot.canvas:minimumTextSize(2, text)
  local main, notice = st.slots.main, st.slots.notice
  if plan.layout then
    place(slot, plan.layout(slot.size, slot.screen))
  else
    place(slot, T.layout(slot.size, slot.screen, plan.slot == "notice" and main and main.frame or nil))
  end
  if plan.slot == "main" and notice then place(notice, T.layout(notice.size, notice.screen, slot.frame)) end
  local step = plan.step
  if plan.slot == "mark" then step = st.step else st.step = step end
  for _, s in pairs(st.slots) do
    local covers = T.hides(s.frame, step)
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
  slot.life = timer.doAfter(plan.life or T.LIFETIME, take_down(st, plan.slot))
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

-- The hook the CLI's mark call reaches, through arngz.lua's M.mark: KIND
-- (start, end or still), its WORDS, and the SECONDS a start or still may
-- stay. Whatever fails is raised with the mark's kind, so the hs call exits
-- non-zero and the CLI's run log says so. A failure a timer kept is left for
-- the next point, whose error the engine logs in full.
function T.mark(kind, words, seconds)
  local ok, err = pcall(function() draw(shared(), T.on_mark(kind, words, seconds)) end)
  if not ok then error("arngz toast: the " .. tostring(kind) .. " mark: " .. tostring(err), 0) end
end

return T
