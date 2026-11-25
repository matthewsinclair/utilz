-- arngz's engine module, loaded by Hammerspoon (ST0026, design.md "The engine").
--
-- The CLI writes a request file and runs
--   hs -c 'return dofile("<this file>").run("<request path>")'
-- and this module writes the response beside the request and returns one
-- status line (D17: files, never a shell-quoted desk). dofile at every call
-- means an edit here is live without reloading Hammerspoon's config.
--
-- Three parts. observe() reads screens, spaces, windows, settings and Dock
-- bindings. plan(desk, world, options) is pure and lives in plan.lua, beside
-- this file, so it can be tested where Hammerspoon cannot run. execute(ops)
-- performs ops and reads back after each one; a move is a person's gesture
-- (D21), ported from dc's spike 2 (arngz-spike2.lua, WP-01), which measured
-- it, and planned leg by leg in plan.lua.
--
-- ONLY PUBLIC hs.* CALLS (D15). hs.spaces is Hammerspoon's own module over the
-- private Spaces API; arngz makes no private call of its own.

local function dirname(path)
  return path:match("^(.*)/[^/]*$")
end

-- plan.lua is found beside this file, never on Hammerspoon's working directory.
local here = dirname(debug.getinfo(1, "S").source:gsub("^@", ""))
if not here then error("arngz: cannot tell which directory this module was loaded from") end
local P = dofile(here .. "/plan.lua")
-- log.lua, beside it: the run log's formatters and its one write (ST589246c).
local L = dofile(here .. "/log.lua")
-- This file's own path, which keys the display watcher (M.watch).
local MODULE = (debug.getinfo(1, "S").source:gsub("^@", ""))

local M = {}

-- A wait reads this often: between phases, or inside the plan verb's call.
local POLL_SECONDS = 0.25

-- How long after the reload verb's answer the reload itself runs, so that
-- the answer is written first (ST6d8eed9 WP a45b3aeb).
local RELOAD_DELAY = 0.5

-- How many times a space creation is tried before it is given up on (issue
-- 0135): a call that made nothing, for a reason that may pass, and the count
-- readback, which can lag behind a creation. The Dock's Mission Control
-- error is not retried, and a vanished display is not either (P.space_error_final).
M.CREATE_SPACE_TRIES = 4

-- ---------------------------------------------------------------- helpers

local function utc_now() return os.date("!%Y-%m-%dT%H:%M:%SZ") end

-- The run arngz_running holds, said with its article: "an apply", or "a
-- reload" while Hammerspoon's config is about to be reloaded (ST6d8eed9 WP
-- a45b3aeb).
local function a_run(running)
  local verb = tostring(running.verb)
  return (verb:match("^[aeiou]") and "an " or "a ") .. verb
end

-- A refusal: raised as a tagged table, so answer() can tell "refused before
-- anything changed" from a Lua error inside the engine (D25). A fix, where
-- the refusal names one, goes into the response for the CLI to print.
local function refuse(why, fix) error({ refused = why, fix = fix }, 0) end

local function rect(r)
  if not r then return nil end
  return { x = r.x, y = r.y, w = r.w, h = r.h }
end

-- A defaults domain through `defaults export`, so cfprefsd answers rather than
-- a plist file it may not have flushed (dc's spike).
local function read_defaults(domain)
  local text, ok, _, rc = hs.execute("/usr/bin/defaults export " .. domain .. " -")
  if not ok then
    return nil, string.format("defaults export %s exited %s", domain, tostring(rc))
  end
  local t = hs.plist.readString(text)
  if type(t) ~= "table" then
    return nil, "could not parse what defaults export " .. domain .. " printed"
  end
  return t
end

-- com.apple.spaces and its Monitors list, which holds each display's desktops
-- in Mission Control's order as of the last display change (D22, WP
-- 93ea7f8a): the one reader observe and the display
-- watcher share. The prefs come back too, for the Dock bindings observe reads.
local function spaces_record()
  local prefs, err = read_defaults("com.apple.spaces")
  local monitors = prefs and prefs.SpacesDisplayConfiguration
    and prefs.SpacesDisplayConfiguration["Management Data"]
    and prefs.SpacesDisplayConfiguration["Management Data"].Monitors
  return monitors, prefs, err
end

-- ---------------------------------------------------------------- the run log

-- THE RUN LOG (ST589246c, WP 53ef07aa). The CLI names the file and the run's
-- id in the request; every run has a log table, so the toast hook and the
-- response's warnings work whether or not there is a file, and with no file
-- nothing is written. A record that cannot be written never changes the run
-- and is never dropped: the first failure and the count go back in the
-- response as log_error, which the CLI says once.
local function new_log(request)
  local path = type(request.log) == "string" and request.log ~= "" and request.log or nil
  local run = type(request.run) == "string" and request.run ~= "" and request.run or "-"
  local clocked, started = pcall(function() return hs.timer.secondsSinceEpoch() end)
  return { path = path, run = run, failures = 0, started = clocked and started or os.time() }
end

-- Append the { event, text } pairs MAKE returns, under SOURCE. MAKE runs
-- inside the guard, so a record that cannot even be built counts as a failed
-- write, kept and never raised into the run.
local function write_log(lg, source, make)
  if not (lg and lg.path) then return end
  local ok, err = pcall(function()
    local stamp = L.stamp(hs.timer.secondsSinceEpoch())
    local lines = {}
    for _, p in ipairs(make()) do
      for _, piece in ipairs(L.split(p[2])) do lines[#lines + 1] = L.record(stamp, lg.run, source, p[1], piece) end
    end
    local wrote, why = L.append(lg.path, lines)
    if not wrote then error(why, 0) end
  end)
  if not ok then
    lg.failures = lg.failures + 1
    lg.first_failure = lg.first_failure or tostring(err)
  end
end

-- One engine record. TEXT is a string, or a function that returns one, for a
-- record whose words need reads that may fail.
local function note(lg, event, text)
  write_log(lg, "engine", function()
    local said = text
    if type(said) == "function" then said = said() end
    return { { event, tostring(said) } }
  end)
end

-- The displays a run saw at LABEL, with the time since the last display change.
local function log_world(lg, label, world)
  if not (lg and lg.path and world) then return end
  write_log(lg, "engine", function()
    return L.world_pairs(world, label, L.since(hs.timer.secondsSinceEpoch(), rawget(_G, "arngz_screens")))
  end)
end

-- ic's toasts (WP eae7633d) hang on the progress points through
-- opt/arngz/lib/toast.lua, loaded when the file is there (progress.md, rule
-- 5). A hook that will not load toasts nothing and is said in each run's log
-- and response. A test sets M.toast itself.
local function load_toast()
  local path = here .. "/toast.lua"
  local f, oerr, errno = io.open(path, "r")
  -- Only a file that is not there means no toasts; one that will not open
  -- is said, as one that will not load is.
  if not f then
    if errno == 2 then return nil end
    return nil, "could not open " .. path .. ": " .. tostring(oerr)
  end
  f:close()
  local ok, t = pcall(dofile, path)
  if not ok then return nil, "could not load " .. path .. ": " .. tostring(t) end
  if type(t) ~= "table" or type(t.point) ~= "function" then return nil, path .. " returns no point function" end
  return t
end
M.toast, M.toast_error = load_toast()

-- A progress point (progress.md): its record, then the toast hook with the
-- same name and fields, `run` on every one. FIELDS is a table, or a function
-- that makes one, and is made inside the guard: a point whose fields cannot
-- be made still goes out, with the error as its one field, so `finished`
-- always comes (rule 3) and the log never fails a run. The hook is guarded
-- too: an error in it is the run's toast_error, logged and answered once,
-- and changes nothing else (rule 6).
local function point(lg, name, fields)
  local made, f = pcall(function()
    local got = fields
    if type(got) == "function" then got = got() end
    if got == nil then got = {} end
    if type(got) ~= "table" then error("the fields are a " .. type(got) .. ", not a table", 0) end
    return got
  end)
  if not made then
    note(lg, "error", "the " .. tostring(name) .. " point's fields could not be made: " .. tostring(f))
    f = { error = tostring(f) }
  end
  f.run = lg and lg.run or "-"
  note(lg, "point", function() return L.point_text(name, f) end)
  if M.toast then
    local ok, err = pcall(M.toast.point, name, f)
    if not ok and lg then
      local why = "the toast hook failed at " .. tostring(name) .. ": " .. tostring(err)
      lg.toast_error = lg.toast_error or why
      note(lg, "error", why)
    end
  end
end

-- The app's own bundle id for a desk's spelling of it. A desk names an app
-- whatever the case (design.md, "An app"), and applicationsForBundleID, which
-- hs.application.get uses, matches only the app's own case (measured 16 Oct
-- 2026: com.apple.Finder finds nothing, com.apple.finder finds Finder).
-- LaunchServices answers in any case. An app it does not know keeps the
-- desk's spelling, and nothing then finds it running, so it reads as not
-- running (ST6d8eed9 WP 35219619). A lookup that raises is nil and why: could
-- not see, never taken for not there.
local function own_id(bundle)
  local ok, info = pcall(hs.application.infoForBundleID, bundle)
  if not ok then return nil, "infoForBundleID(" .. tostring(bundle) .. "): " .. tostring(info) end
  if type(info) == "table" and type(info.CFBundleIdentifier) == "string" then return info.CFBundleIdentifier end
  return bundle
end

-- f() tried up to `times` times, a fifth of a second apart (never after the
-- last): true and its value, or false and the last error. `stop`, when given,
-- is asked about an error and ends the attempts at once when it answers true,
-- for a failure that waiting cannot put right (issue 0135). The retry rule
-- keeps one home: a caller that must not retry says so here rather than
-- writing a loop of its own.
local function attempts(times, f, stop)
  local ok, value
  for i = 1, times do
    ok, value = pcall(f)
    if ok then return true, value end
    if stop and stop(value) then return false, value end
    if i < times then hs.timer.usleep(200000) end
  end
  return false, value
end

-- Every window Hammerspoon can NAME, by id. hs.window.allWindows sees only the
-- visible spaces; the default window filter is the documented route to
-- windows on the others (dc's spike). Which route named a window is kept.
--
-- A window can close, or not be backed yet, between Hammerspoon listing it and
-- reading it, and allWindows then raises from inside hs.axuielement (measured
-- by vc's hand run, 16 Oct 2026). So the listing is retried a few times, and
-- only a failure that persists is recorded, as could-not-read, never as no
-- windows. Every id read that fails is counted, with the first error, so an
-- unseen entry can say a window may have gone unnamed. It counts reads, not
-- windows: both routes list the windows on a shown space, so one window can
-- fail twice, or fail on one route and be named by the other.
-- Returns the index, the filter's note, the listing's error, and
-- { count = n, first = error } for the id reads that failed.
local function nameable()
  local index, id_errors = {}, { count = 0 }
  local function take(w, via)
    local got, id = pcall(function() return w:id() end)
    if not (got and id) then
      id_errors.count = id_errors.count + 1
      id_errors.first = id_errors.first or (got and "no id" or tostring(id))
    elseif not index[id] then
      index[id] = { win = w, via = via }
    end
  end
  local listed, all = attempts(4, hs.window.allWindows)
  if not listed then
    return index, nil, "hs.window.allWindows failed four times: " .. tostring(all), id_errors
  end
  for _, w in ipairs(all) do take(w, "allWindows") end
  local ok, windows = pcall(function() return hs.window.filter.default:getWindows() end)
  if ok then
    for _, w in ipairs(windows) do take(w, "filter.default") end
  end
  local note = "ran"
  if not ok then note = "failed: " .. tostring(windows) end
  return index, note, nil, id_errors
end

-- One window read, or, when it went away or is not backed yet between being
-- listed and being read, unnamed with why: it is not seen, and says so,
-- rather than failing the whole observe.
local describe_one
local function describe(id, index)
  local ok, d = pcall(describe_one, id, index)
  if ok then return d end
  return { id = id, named = false, read_error = tostring(d) }
end

describe_one = function(id, index)
  local hit = index[id]
  if not hit then return { id = id, named = false } end
  local w = hit.win
  local app = w:application()
  local d = {
    id = id,
    named = true,
    via = hit.via,
    title = w:title(),
    frame = rect(w:frame()),
    standard = w:isStandard(),
    minimized = w:isMinimized(),
  }
  if app then
    d.bundle = app:bundleID()
    -- The app's display name beside its bundle, read from the toast's own
    -- source (toast.lua's display_name), so a reason names an app as the
    -- toast does (STca1b7f9 WP4); P.app_label owns the fallback.
    if d.bundle then d.app_name = hs.application.nameForBundleID(d.bundle) end
  end
  return d
end

-- ---------------------------------------------------------------- observe

-- One screen as observe and the display watcher both read it: what it is,
-- where it sits, the desktop it shows, and its desktops live, each error kept
-- beside its value. The one builder of a world.screens entry; observe adds
-- the order and the windows. Returns the entry and the live list.
local function read_screen(scr, primary_uuid, primary_frame)
  local uuid = scr:getUUID()
  local full = rect(scr:fullFrame())
  local active, aerr = hs.spaces.activeSpaceOnScreen(uuid)
  local entry = {
    uuid = uuid,
    name = scr:name(),
    primary = uuid == primary_uuid,
    frame = rect(scr:frame()),
    full_frame = full,
    position = P.position(full, primary_frame),
    active_space = active,
    active_error = aerr,
    spaces = {},
  }
  local spaces, serr = hs.spaces.spacesForScreen(uuid)
  -- Keyed on the missing value, so nil with no message is still unread.
  if not spaces then entry.spaces_error = serr or "spacesForScreen returned nothing" end
  -- The desktops live, in the live list's order, for the run log.
  entry.live = spaces
  return entry, spaces
end

-- The world as it is now. Read-only. Every lookup that can fail records its
-- error beside the value rather than dropping it, because "could not see" and
-- "is not there" need different answers. `bundles`, the desk's app bundle
-- ids, is what is asked about one by one, fresh, for whether it runs.
function M.observe(bundles)
  -- com.apple.spaces first: it holds each display's space order as of the
  -- last display change (D22, WP 93ea7f8a) as well as the Dock bindings.
  local monitors, spaces_prefs, spaces_err = spaces_record()
  local data, derr = hs.spaces.data_managedDisplaySpaces()
  local uuids = {}
  for _, display in ipairs(data or {}) do
    for _, space in ipairs(display.Spaces or {}) do
      uuids[space.ManagedSpaceID] = space.uuid
    end
  end

  local index, filter_note, list_err, id_errors = nameable()
  local primary = hs.screen.primaryScreen()
  local primary_frame = rect(primary:fullFrame())
  local world = {
    taken_at = utc_now(),
    macos = hs.host.operatingSystemVersionString(),
    hammerspoon = hs.processInfo.version,
    accessibility = hs.accessibilityState(false),
    separate_spaces = hs.spaces.screensHaveSeparateSpaces(),
    window_filter = filter_note,
    windows_list_error = list_err,
    window_id_errors = id_errors.count,
    window_id_error = id_errors.first,
    managed_spaces_error = derr,
    -- Every list com.apple.spaces holds, as macOS names it, for the run log
    -- (ST589246c): the order rule reads `monitors` itself, below.
    recorded = L.recorded(monitors),
    recorded_error = spaces_err,
    screens = {},
    apps_running = {},
    app_bindings = {},
  }

  for _, scr in ipairs(hs.screen.allScreens()) do
    local entry, spaces = read_screen(scr, primary:getUUID(), primary_frame)
    local active = entry.active_space
    -- Mission Control's order: com.apple.spaces' where its record of this
    -- screen is current, and the live list's where it is not, as after a
    -- display change (P.order_spaces, WP 93ea7f8a). Where it came from, and
    -- why, go in the run log.
    local ordered = spaces
    if spaces then
      ordered, entry.order_source, entry.order_note = P.order_spaces(spaces, monitors, spaces_err)
    end
    for ordinal, id in ipairs(ordered or {}) do
      local raw, werr = hs.spaces.windowsForSpace(id)
      local windows, named = {}, 0
      for _, wid in ipairs(raw or {}) do
        local d = describe(wid, index)
        if d.named then named = named + 1 end
        windows[#windows + 1] = d
      end
      local stype, terr = hs.spaces.spaceType(id)
      entry.spaces[#entry.spaces + 1] = {
        id = id,
        ordinal = ordinal,
        type = stype,
        type_error = terr,
        uuid = uuids[id],
        active = id == active,
        window_ids = #windows,
        named = named,
        windows_error = (raw == nil) and (werr or "windowsForSpace returned nothing") or nil,
        windows = windows,
      }
    end
    world.screens[#world.screens + 1] = entry
  end

  -- Whether the desk's apps run is asked one bundle at a time, fresh:
  -- runningApplications is NSWorkspace's KVO-backed list, refreshed only when
  -- Hammerspoon's run loop turns, so inside one callback it stays the list
  -- from when the callback began (vc's hand runs at 9907e17, 16 Oct 2026).
  -- applicationsForBundleID asks afresh, as hs.application.get does for a
  -- bundle id (hs/application.lua:146). With no desk (discover, observe) the
  -- sweep is kept, and apps_running_source says which was read. Each read is
  -- tried four times, because a just-launched app can be listed before it
  -- can be read; one that still fails is recorded as unread, naming what,
  -- never left looking like not running.
  if bundles then
    world.apps_running_source = "applicationsForBundleID"
    for _, b in ipairs(bundles) do
      local got, apps = attempts(4, function()
        local id, why = own_id(b)
        if not id then error(why, 0) end
        return hs.application.applicationsForBundleID(id)
      end)
      if not got then
        world.apps_running_error = b .. " could not be read four times: " .. tostring(apps)
        break
      end
      if #apps > 0 then world.apps_running[#world.apps_running + 1] = b end
    end
  else
    world.apps_running_source = "runningApplications"
    local got, read = attempts(4, function()
      local running = {}
      for _, app in ipairs(hs.application.runningApplications()) do
        local b = app:bundleID()
        if b then running[#running + 1] = b end
      end
      return running
    end)
    if got then
      world.apps_running = read
    else
      world.apps_running_error = "the running apps could not be read four times: " .. tostring(read)
    end
  end

  local dock_prefs, dock_err = read_defaults("com.apple.dock")
  local wm_prefs, wm_err = read_defaults("com.apple.WindowManager")
  world.prefs_errors = { spaces = spaces_err, dock = dock_err, window_manager = wm_err }
  -- RAW VALUES, AND NO VERDICT (D26): what an unset key means is the CLI's
  -- pref_verdict's to say, in one place. Read directly, never with
  -- `t and t[k] or nil`, which turns a stored false (mru-spaces is one) into
  -- an absent key (dc's spike). Absent is unset, and stays absent.
  if spaces_prefs then world.spans_displays = spaces_prefs["spans-displays"] end
  if dock_prefs then world.mru_spaces = dock_prefs["mru-spaces"] end
  if wm_prefs then world.globally_enabled = wm_prefs.GloballyEnabled end
  -- Absent means no bindings; present and not a table means they could not be
  -- read, and is recorded, never left looking like none.
  local bindings = spaces_prefs and spaces_prefs["app-bindings"]
  if type(bindings) == "table" then
    for bundle, target in pairs(bindings) do
      world.app_bindings[#world.app_bindings + 1] = { bundle = bundle, target = target }
    end
  elseif bindings ~= nil then
    world.bindings_error = "app-bindings is a " .. type(bindings) .. ", not a table of bindings"
  end
  return world
end

-- ---------------------------------------------------------------- the display watcher

-- WHEN THE DISPLAYS CHANGED, and where every desktop sat after, is what a run
-- cannot see: arngz runs when it is asked, after the change (ST589246c,
-- 53ef07aa's design, "The display watcher"). So the first engine call in a
-- Hammerspoon session starts an hs.screen.watcher, held in a global as
-- arngz_running is, and keyed on this module's path and the log's, so a call
-- from another tree (`utilz use dev`) replaces it. Each change is a `change`
-- record and a snapshot of every display's desktops, at once and after each
-- of SNAPSHOT_AFTER, so the log shows whether and when visiting desktops go
-- home. Its timers live in the same global, so none is collected before it
-- fires and a replaced watcher stops them with it. Everything it runs is
-- guarded, and a failure is an `error` record (vc's read, 23 Nov 2026). A
-- reload of Hammerspoon's config drops it; the next engine call starts it
-- again, and its start is in the log, so a change it missed reads as unseen.
M.SNAPSHOT_AFTER = { 5, 30, 120 }

-- Every display's desktops now, live and recorded, without the windows:
-- lighter than observe, for the snapshots.
local function desktops_now()
  local monitors, _, err = spaces_record()
  local world = { screens = {}, recorded = L.recorded(monitors), recorded_error = err }
  local primary = hs.screen.primaryScreen()
  local primary_uuid, primary_frame = primary:getUUID(), rect(primary:fullFrame())
  for _, scr in ipairs(hs.screen.allScreens()) do
    world.screens[#world.screens + 1] = (read_screen(scr, primary_uuid, primary_frame))
  end
  return world
end

-- A watcher record. With no run to answer, a write that fails goes to
-- Hammerspoon's console instead, as done() says a response it cannot write.
local function watcher_write(state, make)
  local lg = { path = state.log, run = "-", failures = 0 }
  write_log(lg, "displays", make)
  if lg.failures > 0 then
    print("arngz: the display watcher could not write the run log: " .. tostring(lg.first_failure))
  end
end

-- F under a guard: a failure is an error record in the log.
local function watch_guarded(state, what, f)
  local ok, err = pcall(f)
  if not ok then
    watcher_write(state, function() return { { "error", what .. ": " .. tostring(err) } } end)
  end
end

local function snapshot(state, label)
  watch_guarded(state, "the snapshot " .. label, function()
    local world = desktops_now()
    watcher_write(state, function() return L.world_pairs(world, "snapshot " .. label, nil, false) end)
  end)
end

local function display_changed(state)
  state.last_change = hs.timer.secondsSinceEpoch()
  local names = {}
  for _, s in ipairs(hs.screen.allScreens()) do
    names[#names + 1] = tostring(s:getUUID()) .. ' "' .. tostring(s:name()) .. '"'
  end
  watcher_write(state, function()
    return { { "change", #names .. " display(s) attached: " .. table.concat(names, "; ") } }
  end)
  snapshot(state, "at once")
  local pending = {}
  for _, t in ipairs(state.timers) do
    if t:running() then pending[#pending + 1] = t end
  end
  state.timers = pending
  for _, after in ipairs(M.SNAPSHOT_AFTER) do
    local label = after .. " s after the change"
    state.timers[#state.timers + 1] = hs.timer.doAfter(after, function() snapshot(state, label) end)
  end
end

function M.watch(lg)
  if not (lg and lg.path) then return end
  local ok, err = pcall(function()
    local g = rawget(_G, "arngz_screens")
    if g and g.module == MODULE and g.log == lg.path then return end
    if g then
      -- One that will not stop would write beside its replacement: said.
      local stopped, serr = pcall(function() g.watcher:stop() end)
      if not stopped then note(lg, "error", "the watcher being replaced would not stop: " .. tostring(serr)) end
      for _, t in ipairs(g.timers or {}) do
        local ended, terr = pcall(function() t:stop() end)
        if not ended then note(lg, "error", "a snapshot timer of the watcher being replaced would not stop: " .. tostring(terr)) end
      end
      -- Stopped or not, it is cleared before the new one starts: one that
      -- would not stop is no better a clock than one that did. A start that
      -- raises below then leaves no watcher, and the settle counts from when
      -- its wait began, never from a last change that no longer moves (cc's
      -- code read of WP 93ea7f8a, item 2).
      rawset(_G, "arngz_screens", nil)
    end
    local state = { module = MODULE, log = lg.path, started = hs.timer.secondsSinceEpoch(), timers = {} }
    state.watcher = hs.screen.watcher.new(function()
      watch_guarded(state, "the display watcher", function() display_changed(state) end)
    end)
    state.watcher:start()
    rawset(_G, "arngz_screens", state)
    note(lg, "watch", "watching display changes from " .. L.stamp(state.started)
      .. (g and (", in place of the watcher " .. tostring(g.module) .. " started") or ""))
  end)
  if not ok then note(lg, "error", "the display watcher could not start: " .. tostring(err)) end
end

-- ---------------------------------------------------------------- execute

-- How many desktops a screen has, or nil and why it could not be read, so a
-- failed readback is never blamed on the op it was reading back. The third
-- value is the live list the count was read from, so the run log can name the
-- desktop a creation added without a read of its own.
local function user_space_count(uuid)
  local spaces, err = hs.spaces.spacesForScreen(uuid)
  if not spaces then return nil, "spacesForScreen: " .. tostring(err) end
  local n = 0
  for _, id in ipairs(spaces) do
    local stype, terr = hs.spaces.spaceType(id)
    if stype == nil then return nil, "spaceType(" .. tostring(id) .. "): " .. tostring(terr) end
    if P.is_user_space(stype) then n = n + 1 end
  end
  return n, nil, spaces
end

-- The ids in AFTER that BEFORE did not hold: the desktops a creation added.
local function added(before, after)
  local had, out = {}, {}
  for _, id in ipairs(before or {}) do had[id] = true end
  for _, id in ipairs(after or {}) do
    if not had[id] then out[#out + 1] = id end
  end
  return out
end

local function exec_create_space(op, ctx)
  -- A cause that lasts the whole run is said once per display, not once per
  -- op: run 35 of hv's log asked for seven spaces and reported the same Dock
  -- failure seven times (issue 0135). The state is the run's, as ctx.unmoved
  -- is: one record per display, its reason and its fix. The Dock's Mission
  -- Control failure binds every display, since Mission Control is one for all
  -- of them, and prepare asks for every create in one callback (STca1b7f9 WP6).
  ctx.space_failed = ctx.space_failed or {}
  local bound = ctx.space_failed[op.screen] or ctx.dock_failed
  if bound then
    return { status = "failed", fix = bound.fix, reason = string.format(bound.all
      and "creating a space failed at the Dock earlier in this run and was not tried again (%s)"
      or "creating a space on this display already failed and was not tried again (%s)", bound.reason) }
  end
  local before, berr, before_ids = user_space_count(op.screen)
  if not before then
    local reason = "could not count the desktops before: " .. berr
    ctx.space_failed[op.screen] = { reason = reason }
    return { status = "failed", reason = reason }
  end
  -- attempts retries a THROWN error and this call signals by returning nil, so
  -- it is wrapped to raise. error(..., 0) keeps the reason as Hammerspoon gave
  -- it: level 0 adds no file:line prefix, which would otherwise reach the
  -- report. Whether waiting could put a failure right is plan's to say.
  --
  -- A CALL THAT REPORTED A SPACE IS NEVER MADE AGAIN. addSpaceToScreen creates
  -- a desktop, and the desktop list LAGS behind it: user_space_count reads
  -- spacesForScreen, the live list, and this count readback is what waits for
  -- the new desktop to be listed (WP 93ea7f8a). So a count read in the same breath
  -- as the creation cannot be the trigger for another creation -- a lagging
  -- list would make a second, a third and a fourth desktop for one op, and
  -- report done with the extras unaccounted for. `made` is captured, so once
  -- the call has returned a space the remaining attempts only re-read the
  -- count, which is what the retry budget is actually buying. A call that
  -- returned nil made nothing and may honestly be tried again, for a reason
  -- that may pass. Run 35's, the Dock's Mission Control error, which 0135 was
  -- raised for, is not one: four tries never once rode it out, there or in
  -- hv's two runs of 23 Nov, so it stops the tries (STca1b7f9 WP6).
  --
  -- ONE HOLE IS LEFT OPEN ON PURPOSE, so it is not mistaken for an oversight:
  -- a call that returns nil and nonetheless creates a desktop leaves `made`
  -- nil, so the next attempt creates again. Closing it needs a count read
  -- before the first create, which still races, and treating every nil return
  -- as a single attempt would give up the retry of a reason that may pass.
  -- The overshoot arm below makes it visible instead of silent: attempt 2's
  -- readback sees before + 2 and says so by name.
  local made, why, last_ids
  local ok, res = attempts(M.CREATE_SPACE_TRIES, function()
    if not made then
      made, why = hs.spaces.addSpaceToScreen(op.screen, true)
    end
    local now, nerr, now_ids = user_space_count(op.screen)
    if not now then error("could not count the desktops back: " .. tostring(nerr), 0) end
    last_ids = now_ids
    if now == before + 1 then return now end
    if now > before + 1 then
      -- Not a success to be reported done: something made desktops nobody
      -- asked for, and the report has to say so rather than hide it in a
      -- readback.
      error(string.format("the desktops went from %d to %d, more than the one asked for", before, now), 0)
    end
    -- Two different facts, and in the lag case the first is the likelier of
    -- them: a call that reported making a space whose registration never
    -- caught up, and a call that did nothing at all. `why` is nil once the
    -- call has succeeded, so the generic words would assert the opposite of
    -- what Hammerspoon said.
    if made then
      error("it reported making a space and the desktop list never caught up", 0)
    end
    error(tostring(why or "it changed nothing"), 0)
  end, function()
    -- Asked about the CALL's own reason, not about whatever was thrown: a
    -- display that has gone in a way that also breaks spacesForScreen throws
    -- the count's error, and reading that as transient would retry a vanished
    -- display four times, which is the third thing 0135 set out to stop. The
    -- Dock's Mission Control error stops them too (STca1b7f9 WP6): each try
    -- asks the Dock to open Mission Control while it may still be opening.
    -- Which reasons stop them is plan's to say.
    return not made and why ~= nil and P.space_error_final(why)
  end)
  if ok then
    -- `created` names the desktop it added, from the lists the counts were
    -- read from, for the run log (ST589246c).
    return { status = "done", readback = { user_spaces = res }, created = added(before_ids, last_ids) }
  end
  local after = user_space_count(op.screen)
  -- No fixed outer phrase. apply_report prefixes every loose line with the op
  -- and the status, `create_space (<path>): failed:`, so "creating a space did
  -- not take" repeated what the reader already had twice -- and contradicted
  -- the inner fact on two of its four paths, where the call reported making a
  -- space, and where the desktops overshot. The inner clause is the only part
  -- carrying information, so it stands on its own.
  -- The Dock's error said as what it means, with its way out (WP6), from the
  -- call's own reason, which is what the stop read: a count that threw on the
  -- same try goes beside it, never in place of it.
  local dock = not made and why ~= nil and P.space_error_kind(why) == "dock"
  local words, fix = P.create_failure(dock and why or res)
  if dock and tostring(res) ~= tostring(why) then words = words .. "; and " .. tostring(res) end
  local reason = string.format("%s; user spaces %d before, %s after",
    words, before, after and tostring(after) or "a count that could not be read")
  -- Bind the rest of the run only for a cause that lasts: nothing made, or a
  -- count that cannot be read at all. The `made` test is the point -- a call
  -- that DID report a space, whose registration simply never caught up inside
  -- the budget, has not shown that the display is unusable, and binding on it
  -- would refuse every later space there with "already failed" although one
  -- was created and only com.apple.spaces was slow. That is the same defect
  -- this function had on the ok-true path two commits ago, by the other door.
  -- A count that moved by some other amount is likewise this op's failure
  -- alone, said rather than held against the rest of the run.
  if after == nil or (after == before and not made) then ctx.space_failed[op.screen] = { reason = reason, fix = fix } end
  if dock then ctx.dock_failed = { reason = reason, fix = fix, all = true } end
  return { status = "failed", reason = reason, fix = fix }
end

local show_desktop -- below, with the hand
local shown_space -- below, with the readers it is built on

local function exec_place(op, ctx)
  if ctx.unmoved[op.window] then
    return { status = "failed", reason = "not placed: its move did not take, so the frame would be on the wrong space" }
  end
  -- A window on a desktop its display is not showing cannot be placed until
  -- that desktop is shown (design.md, "Moving a window").
  local shown, why = show_desktop(ctx, op.window)
  if not shown then return { status = "failed", reason = "not placed: " .. why } end
  local w = hs.window.get(op.window)
  if not w then return { status = "failed", reason = "window " .. tostring(op.window) .. " is not visible to Accessibility" } end
  w:setFrame(op.frame, 0)
  hs.timer.usleep(150000)
  local got = rect(w:frame())
  -- What the readback means is plan's to decide, not this function's
  -- (issue 0133): an app that fixes its own window size cannot fill the cells
  -- the desk gives it, and a window that went where it was put at a size the
  -- app enforces is as well placed as it can be.
  local outcome = P.place_outcome(got, op.frame)
  if outcome == "placed" then
    return { status = "done", readback = { frame = got } }
  elseif outcome == "own_size" then
    return { status = "done", readback = { frame = got },
      note = P.own_size_note(op.op == "recheck" and "in place" or "placed", got) }
  end
  return { status = "failed", readback = { frame = got }, reason = string.format(
    "setFrame returned, and the window took %s, not %s,%s %sx%s (an app may fix its size or snap it)",
    got and string.format("%s,%s %sx%s", P.round(got.x), P.round(got.y), P.round(got.w), P.round(got.h))
      or "a frame that could not be read",
    P.round(op.frame.x), P.round(op.frame.y), P.round(op.frame.w), P.round(op.frame.h)) }
end

-- ---------------------------------------------------------------- the hand (D21)

-- Ported from dc's spike 2 (arngz-spike2.lua), with its measured constants.
local ABORT_PX = 40   -- the pointer is further than this from where arngz put it: stop
local STEP_PX = 20    -- a drag posts one event per this many points...
local STEP_US = 8000  -- ...this far apart: about 2500 points a second
local POLL_US = 50000 -- a wait reads the spaces this often
local STEP_WAIT = 3   -- seconds a key's step may take before it has failed
local NUDGE_PX = 30   -- a window drag begins after a few points; then the keys
local HOLD_WAIT = 0.3 -- seconds the frame has to follow the nudge (vc's grab probes, 45acc46)

local function now() return hs.timer.absoluteTime() end
local function pause(seconds) hs.timer.usleep(math.floor(seconds * 1e6)) end

local function distance(a, b) return math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2) end

local function list(t)
  local out = {}
  for i, v in ipairs(t or {}) do out[i] = v end
  return out
end

local function contains(t, want)
  for _, v in ipairs(t or {}) do
    if v == want then return true end
  end
  return false
end

-- A stop is the person taking the pointer back: every move from here fails.
local function stop(detail) error({ stop = detail }, 0) end

local function mouse(kind, p, dx, dy)
  local E = hs.eventtap.event
  local ev = E.newMouseEvent(E.types[kind], { x = p.x, y = p.y })
  ev:setFlags({})
  if kind ~= "mouseMoved" then ev:setProperty(E.properties.mouseEventClickState, 1) end
  if dx then ev:setProperty(E.properties.mouseEventDeltaX, P.round(dx)) end
  if dy then ev:setProperty(E.properties.mouseEventDeltaY, P.round(dy)) end
  ev:post()
end

local function press_key(k)
  hs.eventtap.event.newKeyEvent(k.mods, k.keycode, true):post()
  hs.timer.usleep(40000)
  hs.eventtap.event.newKeyEvent(k.mods, k.keycode, false):post()
end

-- The pointer, held for the length of apply's moves. It knows where it last
-- put the pointer, so it can tell when the person has taken it back.
local function new_hand()
  local hand = { down = false, at = nil }

  function hand:check(during)
    if not self.at then return end
    local d = distance(hs.mouse.absolutePosition(), self.at)
    if d > ABORT_PX then
      stop(string.format("the pointer moved %.0f px from where arngz put it, %s", d, during))
    end
  end

  function hand:park(p)
    self:check("before arngz moved it")
    mouse("mouseMoved", p)
    self.at = p
    hs.timer.usleep(30000)
  end

  function hand:hold(seconds, during)
    local deadline = now() + seconds * 1e9
    while now() < deadline do
      hs.timer.usleep(POLL_US)
      self:check(during)
    end
  end

  function hand:press(p)
    self:park(p)
    mouse("leftMouseDown", p)
    self.down = true
    hs.timer.usleep(60000)
  end

  function hand:drag(points)
    for _, target in ipairs(points) do
      local from = self.at
      local steps = math.max(1, math.ceil(distance(from, target) / STEP_PX))
      for i = 1, steps do
        local p = { x = P.round(from.x + (target.x - from.x) * i / steps),
          y = P.round(from.y + (target.y - from.y) * i / steps) }
        mouse("leftMouseDragged", p, p.x - self.at.x, p.y - self.at.y)
        self.at = p
        hs.timer.usleep(STEP_US)
      end
    end
  end

  function hand:release()
    if self.down then
      mouse("leftMouseUp", self.at)
      self.down = false
    end
  end

  return hand
end

-- Wait until done() holds, reading every POLL_US, the pointer checked at each
-- read; false when time runs out.
local function wait_for(hand, seconds, during, done)
  local deadline = now() + seconds * 1e9
  while now() < deadline do
    hs.timer.usleep(POLL_US)
    if done() then return true end
    hand:check(during)
  end
  return done()
end

-- The window itself, its toolbar, or a plain group in the bar: where a press
-- and drag moves the window. A button, a field, a tab or the title is not
-- taken: a click on a document window's title opens a rename popover. This
-- is only a first filter: a group can hold a control (Dictionary's Back and
-- Forward), and some windows follow no synthetic drag at all, so take_hold's
-- frame read-back is the test.
local GRAB_ROLES = { AXWindow = true, AXToolbar = true, AXGroup = true }

local function hit_test(p, id, pid)
  local el = hs.axuielement.systemElementAtPosition(p)
  if not el then return "nothing there" end
  local role = el:attributeValue("AXRole")
  local other = el:pid()
  if pid == nil then return "the window's own app could not be read" end
  if other ~= pid then
    local app = hs.application.applicationForPID(other)
    return "another app's window is on top (" .. tostring(app and app:name() or ("pid " .. tostring(other))) .. ")"
  end
  local win_el = role == "AXWindow" and el or el:attributeValue("AXWindow")
  local hw = win_el and win_el:asHSWindow()
  if not (hw and hw:id() == id) then return "another window" end
  if GRAB_ROLES[role] then return "grab", el, role end
  return "a control (" .. tostring(role) .. ")"
end

-- How many parents of a grab point's element are read for a web area before
-- it is taken to be in none: far deeper than a title bar's tree.
local WEB_AREA_DEPTH = 32

-- The element under a grab point as the log says it (STca1b7f9 WP6): its role,
-- and whether a web area holds it, read up its parents to its window, so a
-- hold that does not take says whether it is WP5's class. A parent that cannot
-- be read is said, never taken for no web area, and the hold goes on.
-- attributeValue answers an Accessibility error as nil and the error, never a
-- raise, so each read's error is raised here for the pcall to keep.
local function element_text(el, role)
  local function read(element, attribute)
    local value, err = element:attributeValue(attribute)
    if err ~= nil then error(tostring(attribute) .. ": " .. tostring(err), 0) end
    return value
  end
  local ok, inside = pcall(function()
    local cur = el
    for _ = 1, WEB_AREA_DEPTH do
      local parent = read(cur, "AXParent")
      if not parent then return false end
      local prole = read(parent, "AXRole")
      if prole == "AXWebArea" then return true end
      if prole == "AXWindow" then return false end
      cur = parent
    end
    return false
  end)
  if not ok then return "an " .. tostring(role) .. " whose parents could not be read: " .. tostring(inside) end
  return "an " .. tostring(role) .. (inside and " inside a web area" or "")
end

-- Raising a window activates its app, which can switch its display to
-- another desktop: true while the window's desktop is still shown, else nil
-- and that, said as that, never as a window on top.
local function still_shown(id)
  local shown, home = shown_space(id)
  if shown == nil then return nil, "after raising it: " .. tostring(home) end
  if not shown then
    return nil, string.format("raising window %s left its display showing space %s, not its space %s",
      tostring(id), tostring(home.at), tostring(home.space))
  end
  return true
end

-- A point on the window's title bar that lands on the bar itself, with the
-- window's frame, or nil and every point tried.
local function grab_point(id)
  local win
  -- A desktop just brought into view takes a moment to show its windows to
  -- Accessibility.
  for _ = 1, 20 do
    win = hs.window.get(id)
    if win then break end
    hs.timer.usleep(POLL_US)
  end
  if not win then return nil, "window " .. tostring(id) .. " is not visible to Accessibility on its desktop" end
  -- Raised first: a window behind another cannot be held, and a press there
  -- takes the other app's window (vc's hand run at 9907e17, 16 Oct 2026).
  -- The readback is the hit test, read fresh from Accessibility at each
  -- point, for up to a second while the window comes to the front;
  -- frontmostWindow goes through NSWorkspace, which a callback sees stale.
  win:focus()
  local app = win:application()
  local pid = app and app:pid()
  local frame, zoom = rect(win:frame()), rect(win:zoomButtonRect())
  local tried
  local deadline = now() + 1e9
  repeat
    local still, why = still_shown(id)
    if not still then return nil, why end
    tried = {}
    for _, p in ipairs(P.grab_candidates(frame, zoom)) do
      local verdict, el, role = hit_test(p, id, pid)
      -- The element is kept for the log, which reads its parents only when
      -- there is a log to write to (pressing).
      if verdict == "grab" then return { point = p, frame = frame, el = el, role = role } end
      tried[#tried + 1] = string.format("(%d,%d) %s", p.x, p.y, verdict)
    end
    hs.timer.usleep(POLL_US)
  until now() >= deadline
  return nil, "no point on window " .. tostring(id) .. "'s title bar lands on the bar itself: " .. table.concat(tried, "; ")
end

-- A mouse button or a modifier held changes what a drag does: refused before
-- anything changes (design.md, apply 6), and checked again before the moves.
local function hands_free()
  for k, v in pairs(hs.mouse.getButtons()) do
    if v == true then return nil, "mouse button " .. tostring(k) .. " is held; let go and run apply again" end
  end
  local mods = hs.eventtap.checkKeyboardModifiers()
  for _, m in ipairs({ "cmd", "alt", "shift", "ctrl", "fn" }) do
    if mods[m] then return nil, "the " .. m .. " key is held, and a held modifier changes what a drag does" end
  end
  return true
end

-- The Move-space shortcuts, left and right, or nil and why.
local function move_keys()
  local prefs, err = read_defaults("com.apple.symbolichotkeys")
  if not prefs then return nil, "com.apple.symbolichotkeys could not be read: " .. tostring(err) end
  local left, lerr = P.hotkey(prefs, P.MOVE_LEFT)
  if not left then return nil, lerr end
  local right, rerr = P.hotkey(prefs, P.MOVE_RIGHT)
  if not right then return nil, rerr end
  return { left = left, right = right }
end

-- Where things are now, as P.move_legs reads them: each screen's order and
-- its spaces' types from the latest observe (neither changes while windows
-- move), and the active spaces read live. Each space's named apps, and each
-- named window's app, come from the same observe, for a failed move's words.
local function now_state(world)
  local state = { order = {}, types = {}, active = {}, active_error = {}, screens = {} }
  state.apps, state.window_app = P.named_apps(world)
  for _, s in ipairs(world.screens or {}) do
    local ids = {}
    for _, sp in ipairs(s.spaces or {}) do
      ids[#ids + 1] = sp.id
      state.types[sp.id] = sp.type
    end
    state.order[s.uuid] = ids
    state.active[s.uuid], state.active_error[s.uuid] = hs.spaces.activeSpaceOnScreen(s.uuid)
    state.screens[#state.screens + 1] = { uuid = s.uuid, full = s.full_frame, frame = s.frame }
  end
  return state
end

local function screen_of(state, uuid)
  for _, s in ipairs(state.screens) do
    if s.uuid == uuid then return s end
  end
  return nil
end

local function centre(r) return { x = P.round(r.x + r.w / 2), y = P.round(r.y + r.h / 2) } end

-- Each leg returns nil when it took, or why it did not.
local LEG = {}

-- One step of a gesture and what it read back, in the run log (ST589246c). A
-- step's failure is the op's reason, which the op's own record carries.
local function step_note(ctx, text)
  if ctx and ctx.lg then note(ctx.lg, "step", text) end
end

-- Nothing held: the display under the pointer steps along its order.
function LEG.switch(ctx, leg)
  local scr = screen_of(ctx.state, leg.screen)
  ctx.hand:park(centre(scr.frame))
  for _, step in ipairs(leg.steps) do
    press_key(ctx.keys[leg.side])
    local took = wait_for(ctx.hand, STEP_WAIT, "while showing a desktop", function()
      return hs.spaces.activeSpaceOnScreen(leg.screen) == step
    end)
    if not took then
      local at, aerr = hs.spaces.activeSpaceOnScreen(leg.screen)
      return string.format("pressed Move-space %s with nothing held, and after %d s screen %s shows %s, not space %s",
        leg.side, STEP_WAIT, tostring(leg.screen), at and ("space " .. tostring(at)) or ("what could not be read: " .. tostring(aerr)),
        tostring(step))
    end
    step_note(ctx, string.format("switch: pressed Move-space %s with nothing held; screen %s shows space %s",
      tostring(leg.side), tostring(leg.screen), tostring(step)))
  end
  return nil
end

-- Held: the window carried one step per key press, each step watched.
-- The window held, raised first, and its desktop still shown: raising
-- activates the app, which can switch a display to another desktop.
local function held_point(id)
  local g, why = grab_point(id)
  if not g then return nil, why end
  local still, swhy = still_shown(id)
  if not still then return nil, swhy end
  return g
end

-- Press at the grab point and nudge dx points, then read the window's frame
-- through Accessibility until it follows, for up to HOLD_WAIT. nil when the
-- hold took; else the button is let go and why, and nothing more is done
-- with it held: Dictionary's and Stickies' windows follow no synthetic drag,
-- and a Move-space pressed holding nothing switches the display and leaves
-- the window behind (vc's hands-off re-run at 45acc46, 16 Oct 2026).
local function take_hold(hand, id, g, dx)
  local win = hs.window.get(id)
  local app = win and win:application()
  hand:press(g.point)
  hand:drag({ { x = g.point.x + dx, y = g.point.y } })
  local why
  local took = wait_for(hand, HOLD_WAIT, "while taking hold of the window", function()
    local ok
    ok, why = P.hold_took(g.frame, win and rect(win:frame()), dx)
    return ok == true
  end)
  if took then return nil end
  hand:release()
  return string.format("the hold did not take window %s of %s: %s", tostring(id),
    tostring(app and app:name() or "an app that could not be read"), tostring(why))
end

-- In the run log before a hold presses: the point, and the element under it
-- with whether a web area holds it (STca1b7f9 WP6), so a hold that does not
-- take says whether it is WP5's class.
local function pressing(ctx, kind, id, g)
  -- A caller with no log makes no read for the log alone, as execute's own
  -- timing does.
  if not (ctx and ctx.lg) then return end
  step_note(ctx, string.format("%s: pressing window %s at %s,%s on %s", kind, tostring(id), tostring(g.point.x),
    tostring(g.point.y), element_text(g.el, g.role)))
end

function LEG.carry(ctx, leg, id)
  local g, why = held_point(id)
  if not g then return why end
  local hand = ctx.hand
  pressing(ctx, "carry", id, g)
  local missed = take_hold(hand, id, g, leg.side == "right" and NUDGE_PX or -NUDGE_PX)
  if missed then return missed end
  step_note(ctx, string.format("carry: held window %s at %s,%s", tostring(id), tostring(g.point.x), tostring(g.point.y)))
  hand:hold(0.1, "before the keys")
  for _, step in ipairs(leg.steps) do
    press_key(ctx.keys[leg.side])
    local took = wait_for(hand, STEP_WAIT, "while holding the window", function()
      return P.landed(list(hs.spaces.windowSpaces(id)), hs.spaces.activeSpaceOnScreen(leg.screen), step, leg.screen) == true
    end)
    if took then
      step_note(ctx, string.format("carry: pressed Move-space %s holding window %s; it is on space %s, which screen %s shows",
        tostring(leg.side), tostring(id), tostring(step), tostring(leg.screen)))
    end
    if not took then
      hand:release()
      local spaces, serr = hs.spaces.windowSpaces(id)
      local at, aerr = hs.spaces.activeSpaceOnScreen(leg.screen)
      local _, where = P.landed(spaces and list(spaces), at, step, leg.screen, serr, aerr)
      return string.format("held and pressed Move-space %s, and after %d s %s", leg.side, STEP_WAIT, where)
    end
  end
  hand:hold(0.15, "before letting go")
  hand:release()
  return nil
end

-- Held: dragged over the shared edges onto the target display's shown space.
-- With `check`, the window is read back on that space, shown, before the next
-- leg (STca1b7f9 WP3): a round through another display goes on only from a
-- window that is there.
function LEG.drag(ctx, leg, id)
  local chain = P.route(ctx.state.screens, leg.from_screen, leg.screen)
  if not chain then
    return "no chain of shared edges joins screen " .. tostring(leg.from_screen) .. " to " .. tostring(leg.screen)
  end
  local g, why = held_point(id)
  if not g then return why end
  local dest = P.drop_point(g.point, g.frame, chain[#chain])
  local hand = ctx.hand
  pressing(ctx, "drag", id, g)
  local missed = take_hold(hand, id, g, dest.x >= g.point.x and NUDGE_PX or -NUDGE_PX)
  if missed then return missed end
  hand:drag(P.path(chain, g.point, dest))
  hand:hold(0.2, "before letting go")
  hand:release()
  step_note(ctx, string.format("drag: carried window %s from screen %s to screen %s and let go at %s,%s",
    tostring(id), tostring(leg.from_screen), tostring(leg.screen), tostring(dest.x), tostring(dest.y)))
  if not leg.check then return nil end
  local landed = wait_for(hand, STEP_WAIT, "while the window lands", function()
    return P.landed(list(hs.spaces.windowSpaces(id)), hs.spaces.activeSpaceOnScreen(leg.screen), leg.space,
      leg.screen) == true
  end)
  if landed then
    step_note(ctx, string.format("drag: window %s is on space %s, which screen %s shows", tostring(id),
      tostring(leg.space), tostring(leg.screen)))
    return nil
  end
  local spaces, serr = hs.spaces.windowSpaces(id)
  local shown, aerr = hs.spaces.activeSpaceOnScreen(leg.screen)
  local _, where = P.landed(spaces and list(spaces), shown, leg.space, leg.screen, serr, aerr)
  return string.format("dragged window %s to screen %s, and after %d s %s", tostring(id), tostring(leg.screen),
    STEP_WAIT, where)
end

-- Where a window is, as macOS says: each of its spaces with that space's
-- screen and the space the screen shows, or nil and what could not be read.
-- The one reader window_home and shown_space are built on.
local function window_where(id)
  local spaces, serr = hs.spaces.windowSpaces(id)
  if not spaces then return nil, "windowSpaces(" .. tostring(id) .. "): " .. tostring(serr) end
  local out = {}
  for _, space in ipairs(list(spaces)) do
    local screen, derr = hs.spaces.spaceDisplay(space)
    if not screen then return nil, "spaceDisplay(" .. tostring(space) .. "): " .. tostring(derr) end
    local at, aerr = hs.spaces.activeSpaceOnScreen(screen)
    if at == nil then return nil, "activeSpaceOnScreen(" .. tostring(screen) .. "): " .. tostring(aerr) end
    out[#out + 1] = { space = space, screen = screen, at = at }
  end
  return out
end

-- The one space a window is on, with its screen, or nil and why.
local function window_home(id)
  local where, why = window_where(id)
  if not where then return nil, why end
  if #where ~= 1 then
    return nil, string.format("window %s is on %d spaces", tostring(id), #where)
  end
  return where[1]
end

-- Whether a window is listed on a space, or nil and why it could not be read.
local function listed(space, id)
  local ids, err = hs.spaces.windowsForSpace(space)
  if not ids then return nil, string.format("windowsForSpace(%s): %s", tostring(space), tostring(err)) end
  return contains(ids, id)
end

-- The readback after a move, everything that could not be read kept as an
-- error beside it, never read as "not there".
local function move_readback(op, origin)
  local rb = { origin = origin, errors = {} }
  local spaces, serr = hs.spaces.windowSpaces(op.window)
  if not spaces then rb.errors[#rb.errors + 1] = "windowSpaces: " .. tostring(serr) end
  rb.window_spaces = list(spaces)
  local shown, aerr = hs.spaces.activeSpaceOnScreen(op.screen)
  if shown == nil then rb.errors[#rb.errors + 1] = "activeSpaceOnScreen: " .. tostring(aerr) end
  rb.shown = shown
  local lerr
  rb.listed_at_destination, lerr = listed(op.space, op.window)
  if lerr then rb.errors[#rb.errors + 1] = lerr end
  if origin ~= op.space then
    rb.listed_at_origin, lerr = listed(origin, op.window)
    if lerr then rb.errors[#rb.errors + 1] = lerr end
  else
    rb.listed_at_origin = false
  end
  return rb
end

-- Run legs in order, keeping ctx.state's shown spaces current. Returns nil
-- when they all took, or why not and the index of the leg that did not. A
-- stop, the person taking the pointer, marks ctx.taken with its words:
-- organise then pauses the run, or ends its moves (ST6d8eed9 WP 4cb617e2).
local function run_legs(ctx, legs, id)
  for i, leg in ipairs(legs) do
    step_note(ctx, string.format("leg %s: screen %s%s, steps %s, Move-space %s", tostring(leg.kind), tostring(leg.screen),
      leg.from_screen and (" from screen " .. tostring(leg.from_screen)) or "", L.ids(leg.steps), tostring(leg.side)))
    local ok, err = pcall(LEG[leg.kind], ctx, leg, id)
    if not ok then
      local released, rerr = pcall(function() ctx.hand:release() end)
      local let_go = released and "" or ("; and letting go of the button failed: " .. tostring(rerr))
      if type(err) == "table" and err.stop then
        ctx.taken = err.stop
        return "stopped: " .. err.stop .. let_go, i
      end
      return "lua error in the " .. leg.kind .. " leg: " .. tostring(err) .. let_go, i
    end
    if err then return leg.kind .. ": " .. err, i end
    for _, screen in ipairs({ leg.screen, leg.from_screen }) do
      ctx.state.active[screen], ctx.state.active_error[screen] = hs.spaces.activeSpaceOnScreen(screen)
    end
  end
  return nil
end

-- Whether one of a window's spaces is the one its display shows: true, or
-- false and the first of its spaces with that display and what it shows, or
-- nil and what could not be read. A window on several spaces is shown when
-- any of them is.
shown_space = function(id)
  local where, why = window_where(id)
  if not where then return nil, why end
  if #where == 0 then return nil, "window " .. tostring(id) .. " is on no space" end
  local spaces = {}
  for _, w in ipairs(where) do
    if w.at == w.space then return true end
    spaces[#spaces + 1] = w.space
  end
  local first = where[1]
  return false, { space = first.space, screen = first.screen, at = first.at, count = #where, spaces = spaces }
end

-- Take the pointer for the moves: where things are, where the pointer and the
-- focus were, so they go back. True, or nil and why a person's hand is on it.
local function take_hand(ctx)
  local free, why = hands_free()
  if not free then return nil, why end
  ctx.state = now_state(ctx.world)
  ctx.pointer = ctx.pointer or hs.mouse.absolutePosition()
  ctx.focused = ctx.focused or hs.window.focusedWindow()
  return true
end

-- Show the desktop a window is on, with nothing held, when its display is
-- showing another: true, or nil and why.
show_desktop = function(ctx, id)
  local shown, home = shown_space(id)
  if shown == nil then return nil, home end
  if shown then return true end
  if home.count > 1 then
    return nil, string.format("window %s is on spaces {%s}, none of them shown", tostring(id), table.concat(home.spaces, ","))
  end
  if ctx.stopped then return nil, "its desktop is not shown, and " .. ctx.stopped end
  if not ctx.keys then
    return nil, "its desktop is not shown, and showing it needs the Move-space keys: " .. tostring(ctx.keys_error)
  end
  -- The person may have switched a desktop since apply decided it needed no
  -- hand: take it now.
  if not ctx.state then
    local took, why = take_hand(ctx)
    if not took then return nil, "its desktop is not shown, and " .. why end
  end
  local steps, side = P.walk(ctx.state.order[home.screen], home.at, home.space)
  if not steps then return nil, "space " .. tostring(home.space) .. " is not in screen " .. tostring(home.screen) .. "'s order" end
  local why = run_legs(ctx, { { kind = "switch", screen = home.screen, steps = steps, side = side } }, id)
  if why then return nil, why end
  return true
end

-- Everything apply took goes back, each on its own, whatever happened, and a
-- restore that failed is a result: a button left down is the person's.
local function give_back(ctx, results)
  local function restore(what, f)
    local ok, rerr = pcall(f)
    if not ok then results[#results + 1] = { op = "restore", status = "failed", reason = what .. ": " .. tostring(rerr) } end
  end
  restore("letting go of the mouse button", function() ctx.hand:release() end)
  if ctx.pointer then
    restore("putting the pointer back", function() hs.mouse.absolutePosition(ctx.pointer) end)
  end
  if ctx.focused then
    restore("giving focus back", function()
      local shown, why = shown_space(ctx.focused:id())
      if shown == nil then error(why, 0) end
      if shown then
        ctx.focused:focus()
      else
        -- As the design says: focus goes back only to a desktop being shown.
        -- Said, and counted against nothing.
        results[#results + 1] = { op = "restore", status = "note",
          reason = "focus left where it is: the window that had it is on a desktop no longer shown" }
      end
    end)
  end
end

-- A move's legs, from where its window is now and from ctx.state: the one
-- reading that exec_move and the move's step point share (STca1b7f9 WP3), so
-- the step says the route the op will take. Returns the move and
-- P.move_legs' answer, or nil, nil and why the window's place was not read.
local function move_plan(op, ctx)
  local home, herr = window_home(op.window)
  if not home then return nil, nil, herr end
  local move = {
    screen = op.screen, space = op.space, ordinal = op.ordinal, from_screen = home.screen, from_space = home.space,
    app = ctx.state.window_app[op.window] or P.app_label(nil, op.bundle), names = ctx.names or {},
  }
  return move, P.move_legs(ctx.state, move)
end

-- The display a move's step point says it goes round through, from the state
-- the op will see. The op keeps what was said, false for a move the step did
-- not route round, so that the op can say so if it routes otherwise when it
-- runs; a move the step could not route says why in the log.
local function step_via(op, ctx)
  if not (ctx and ctx.state) then return nil end
  local move, legs, why = move_plan(op, ctx)
  op.step_via = (legs and legs.via) or false
  if not legs then
    step_note(ctx, "route: the step could not route the move: " .. tostring(why))
    return nil
  end
  if not legs.via then return nil end
  return P.display_label(move.names, legs.via)
end

local function exec_move(op, ctx)
  if ctx.stopped then
    return { status = "failed", reason = "not tried: " .. ctx.stopped }
  end
  if not ctx.keys then
    return { status = "failed", reason = "not tried: " .. tostring(ctx.keys_error) }
  end
  local move, legs, why, fix, passed = move_plan(op, ctx)
  if not legs then return { status = "failed", reason = why, fix = fix, passed = passed } end
  -- The displays can change between the step point and this callback, so the
  -- op routes again, and the log says when the two differ.
  if op.step_via ~= nil and op.step_via ~= (legs.via or false) then
    step_note(ctx, string.format("route: the step said %s, and the move goes %s", P.route_said(move.names, op.step_via),
      P.route_said(move.names, legs.via)))
  end
  local failed, at = run_legs(ctx, legs, op.window)
  if failed then
    -- From the drag to B on, the window may wait on B: the failure says where
    -- it is now, read, never assumed.
    if P.round_moved(legs, at) then
      local where, werr = window_home(op.window)
      return { status = "failed", reason = P.round_failure(ctx.state, move, where, werr, failed) }
    end
    return { status = "failed", reason = failed }
  end
  -- The readback (design.md, "Moving a window"): a gesture has no return
  -- value, so this is the only evidence the move happened.
  if #legs > 0 then pause(0.5) end
  local rb = move_readback(op, move.from_space)
  local status, reason = P.move_verdict(rb, op, #legs > 0)
  -- A done round says in the op's record that it went round (WP3).
  if status == "done" and legs.via then reason = P.route_said(move.names, legs.via) end
  return { status = status, reason = reason, readback = rb }
end

-- Ops that ask for nothing to be done, and the status the report gives them.
local REPORT_ONLY = { unseen = "unseen", not_running = "not_running", gone = "failed", unmovable = "failed",
  no_space = "failed" }

-- A recheck is a place (ST0034): the same gesture and readback, so an app that
-- stops holding its own size is re-sized, and its result clears the record.
local EXEC = { create_space = exec_create_space, move = exec_move, place = exec_place, recheck = exec_place }

-- The kinds of op execute performs, which are the ones a step point stands
-- for; log_test holds log.lua's PLANNED_FIELD to them (ST589246c).
function M.acting_kinds()
  local out = {}
  for kind in pairs(EXEC) do out[#out + 1] = kind end
  table.sort(out)
  return out
end

-- Perform each op in order and read back after each one (D14). Nothing is
-- reported done that the readback does not show. ctx carries the hand, the
-- Move-space keys and where things are, for the moves.
function M.execute(ops, ctx)
  ctx = ctx or {}
  ctx.unmoved = ctx.unmoved or {}
  local results = {}
  for i, op in ipairs(ops or {}) do
    local r
    -- Timed only for the run log, so a caller with no log makes no clock read.
    local t0 = ctx.lg and now()
    if REPORT_ONLY[op.op] then
      -- A report-only op's fix goes with its reason (STca1b7f9 WP6).
      r = { status = REPORT_ONLY[op.op], reason = op.reason, fix = op.fix }
      -- An app that is not running is named as LaunchServices names it, for
      -- the Finished point's list (ST6d8eed9 WP 35219619). A lookup that
      -- fails leaves the bundle id, which P.app_label then says.
      if op.op == "not_running" then
        local named, name = pcall(hs.application.nameForBundleID, op.bundle)
        if named and type(name) == "string" then r.app_name = name end
      end
    elseif EXEC[op.op] then
      local ok, res = pcall(EXEC[op.op], op, ctx)
      if ok then r = res else r = { status = "failed", reason = "lua error: " .. tostring(res) } end
    else
      r = { status = "failed", reason = "unknown op " .. tostring(op.op) }
    end
    if op.op == "move" and r.status ~= "done" then ctx.unmoved[op.window] = true end
    r.op = op.op
    r.index = i
    r.path = op.path
    r.bundle = op.bundle
    -- The frame a place or recheck wanted, which P.own_sizes_after reads the
    -- readback against (ST0034).
    if P.PLACING[op.op] then r.want = op.frame end
    -- An unseen op's mark, which plan set and apply's report reads (issue 0132).
    r.uncounted = op.uncounted
    results[#results + 1] = r
    if ctx.lg then note(ctx.lg, "op", function() return L.result_text(op, r, (now() - t0) / 1e6) end) end
  end
  return results
end

-- ---------------------------------------------------------------- apply

local function only(ops, kinds)
  local out = {}
  for _, op in ipairs(ops or {}) do
    if kinds[op.op] then out[#out + 1] = op end
  end
  return out
end

local function except(ops, kinds)
  local out = {}
  for _, op in ipairs(ops or {}) do
    if not kinds[op.op] then out[#out + 1] = op end
  end
  return out
end

local function append(into, from)
  for _, x in ipairs(from) do into[#into + 1] = x end
end

-- What the settles wait for, shared by the plan verb's blocking wait and
-- apply's phases. Each takes the world just observed.

-- A plan that finds an entry unseen is planned again from fresh observes for
-- up to this long: a window on a desktop its display is not showing is named
-- in one read and not the next (vc's hand run, 16 Oct 2026), so one read is
-- not taken as the answer.
local UNSEEN_SECONDS = 1.5

local function has_unseen(ops) return #only(ops, { unseen = true }) > 0 end

-- In the run log, each app a plan took as running though it read as not
-- running, by the window from the start still listed (STca1b7f9 WP6). HELD
-- carries options, world and lg: the job, or the plan verb's own.
local function note_taken(held)
  local options = held.options or {}
  if not options.running_before then return end
  local taken = P.taken_in(held.world, options)
  local keys = {}
  for key in pairs(taken) do keys[#keys + 1] = key end
  table.sort(keys)
  for _, key in ipairs(keys) do
    note(held.lg, "running", string.format("%s read as not running, but its window %s from the start is still listed,"
      .. " so it is taken as running", key, tostring(taken[key])))
  end
end

-- One retry of a plan that found an entry unseen, from WORLD. held carries
-- desk, options, and the ops and world in hand. The plan in hand is the last
-- one plan made from a world it could read: a retry plan refuses (a listing
-- that failed for a moment, which unread() refuses) does not replace it. A
-- crash in plan is raised, never taken for an unseen entry. True once
-- nothing is unseen.
local function retry_unseen(held, world)
  -- Nor does a retry from a world whose window filter failed, when the plan
  -- in hand's world had it run (STca1b7f9 WP6, issue I7fce35c): that read
  -- unnamed every window on a desktop not shown, which is no news of them.
  local takes, why = P.retry_takes(held.world, world)
  if not takes then
    note(held.lg, "wait", "unseen: a retry's read is not taken: " .. tostring(why))
    return false
  end
  local o, err = P.plan(held.desk, world, held.options)
  if not o then
    note(held.lg, "wait", "unseen: a retry's plan refused, so the plan in hand stands: " .. tostring(err))
    return false
  end
  held.ops, held.world = o, world
  -- The plan in hand changed, so the log shows the plan organise will run.
  write_log(held.lg, "engine", function() return L.plan_pairs(o, P.plan_report(o)) end)
  note_taken(held)
  return not has_unseen(o)
end

-- Observe until done(world) holds, for up to `seconds` on the monotonic
-- clock, a quarter of a second between reads, all inside one call. Only the
-- plan verb waits this way, because it answers within the IPC call; apply
-- waits in phases instead, since nothing NSWorkspace, Accessibility or
-- Spaces learns reaches Hammerspoon while one callback runs. An observe that
-- raises while a window is half there is tried again; done() is not guarded,
-- so a crash in it is raised. Returns the last world read, or nil and the
-- last error when no observe succeeded.
local function observe_until(done, seconds, bundles)
  local deadline = now() + seconds * 1e9
  local world, err
  while true do
    local ok, got = pcall(M.observe, bundles)
    if ok then
      world = got
      if done(world) then return world end
    else
      err = got
    end
    if now() >= deadline then break end
    pause(POLL_SECONDS)
  end
  return world, err
end

-- The plan verb: plan from WORLD, planned again from fresh observes while an
-- entry is unseen, up to UNSEEN_SECONDS. Returns the ops, or plan's refusal
-- and its fix.
local function plan_settled(desk, world, options)
  local ops, err, fix = P.plan(desk, world, options)
  if not (ops and has_unseen(ops)) then return ops, err, fix end
  local held = { desk = desk, options = options, ops = ops, world = world }
  observe_until(function(w) return retry_unseen(held, w) end, UNSEEN_SECONDS, P.desk_bundles(desk))
  return held.ops, nil
end

-- ---------------------------------------------------------------- apply, in phases

-- apply, steps 5 to 11 of design.md "apply, in order", everything after the
-- CLI's preconditions and validation, as phases, one timer callback each, so
-- Hammerspoon's run loop turns between them and NSWorkspace, Accessibility
-- and Spaces catch up (vc's hand runs at 9907e17, 16 Oct 2026: inside one
-- callback the running apps stayed as they were for 20 s). A wait is a
-- phase that schedules itself again; nothing sleeps between phases.
--
-- Each phase takes the job and returns the next phase's name and the delay
-- before it, or nothing when it has answered. A refusal before anything
-- changed is refused, which the CLI reports as exit 2. Once job.changed, a
-- phase that fails is a result instead and apply goes to finish, so the
-- report always says what was done.
local PHASE = {}

local ACCESSIBILITY = "Hammerspoon has no Accessibility grant, so it can neither name a window nor move one:"
  .. " System Settings > Privacy & Security > Accessibility"

-- One read of a wait: observe, then done(world), unguarded so a crash in it
-- is raised. The phase itself again, until done holds or `seconds` from its
-- first read have passed; then `next_phase`. When `must_observe`, a wait in
-- which no observe succeeded raises the last error; otherwise what is in
-- hand stands.
-- What each wait is for, in the waiting point's words (progress.md). still is
-- a pause for the pointer (ST6d8eed9 WP 4cb617e2).
local WAIT_FOR = { quiet = "the displays to settle", unseen = "unseen windows", created = "new desktops",
  still = "the pointer to be still" }

-- A wait's start and end in the run log, and its point when it starts, with
-- any EXTRA fields the wait's point carries. After the creates, the displays
-- are logged as the read found them: whether macOS had recorded the new
-- desktops, and where (ST589246c, AC-53ef07aa.3).
local function wait_began(job, name, seconds, extra)
  job.waited = job.waited or {}
  job.waited[name] = now()
  note(job.lg, "wait", string.format("%s: for %s, up to %s s", name, WAIT_FOR[name] or name, tostring(seconds)))
  local fields = { ["for"] = WAIT_FOR[name] or name, seconds = seconds }
  for k, v in pairs(extra or {}) do fields[k] = v end
  point(job.lg, "waiting", fields)
end

local function wait_ended(job, name, how, world)
  if not (job.lg and job.lg.path) then return end
  local since = job.waited and job.waited[name]
  note(job.lg, "wait", string.format("%s: %s after %s ms", name, how,
    since and tostring(math.floor((now() - since) / 1e6)) or "?"))
  if name == "created" then log_world(job.lg, "after creating", world) end
end

local function waiting(job, name, seconds, done, next_phase, must_observe)
  if not job.deadlines[name] then wait_began(job, name, seconds) end
  job.deadlines[name] = job.deadlines[name] or (now() + seconds * 1e9)
  local ok, world = pcall(M.observe, job.bundles)
  if ok then
    job.observed[name] = true
    if done(world) then
      wait_ended(job, name, "done", world)
      return next_phase
    end
  else
    job.observe_errors[name] = world
  end
  if now() < job.deadlines[name] then return name, POLL_SECONDS end
  wait_ended(job, name, "timed out", ok and world or nil)
  if must_observe and not job.observed[name] then error("observe: " .. tostring(job.observe_errors[name]), 0) end
  return next_phase
end

-- Plan from job.world with job.options: the held plan, then a wait while an
-- entry is unseen, then `after`. A refusal is plan's err and fix, for the
-- caller. Every plan goes in the run log; the planned point goes out for the
-- first one alone (progress.md, rule 1).
local function plan_then(job, after)
  local ops, err, fix = P.plan(job.desk, job.world, job.options)
  if not ops then
    note(job.lg, "refused", "the plan: " .. tostring(err) .. (fix and ("; fix: " .. tostring(fix)) or ""))
    if not job.planned then point(job.lg, "planned", function() return L.planned_fields(nil, err) end) end
    job.planned = true
    return nil, err, fix
  end
  write_log(job.lg, "engine", function() return L.plan_pairs(ops, P.plan_report(ops)) end)
  note_taken(job)
  if not job.planned then point(job.lg, "planned", function() return L.planned_fields(ops) end) end
  job.planned = true
  job.ops, job.after_unseen = ops, after
  job.deadlines.unseen, job.observed.unseen, job.observe_errors.unseen = nil, nil, nil
  if has_unseen(ops) then return "unseen", POLL_SECONDS end
  return after
end

-- Before step 5 (WP 93ea7f8a): the displays settle before apply reads them,
-- judged from the display watcher's state alone, so nothing is read while a
-- replug flaps. Each look is a timer, never a sleep inside a callback; the
-- wait is logged and pointed once, and one that outlasts P.QUIET_LIMIT
-- refuses, with nothing changed.
function PHASE.quiet(job)
  local t = hs.timer.secondsSinceEpoch()
  job.quiet_began = job.quiet_began or t
  local verdict, a, b = P.quiet_verdict(t, rawget(_G, "arngz_screens"), job.quiet_began)
  local began = job.waited and job.waited.quiet
  if verdict == "go" then
    if began then wait_ended(job, "quiet", "done", nil) end
    return "inventory"
  end
  if verdict == "refuse" then
    if began then wait_ended(job, "quiet", "timed out", nil) end
    refuse(a, b)
  end
  if not began then wait_began(job, "quiet", P.QUIET_LIMIT) end
  return "quiet", a
end

-- Step 5: observe, match, plan.
function PHASE.inventory(job)
  job.bundles = P.desk_bundles(job.desk)
  job.world = M.observe(job.bundles)
  log_world(job.lg, "start", job.world)
  point(job.lg, "observed", function() return L.observed_fields(job.world) end)
  -- Only Hammerspoon can say whether it holds the grant; the preferences are
  -- the CLI's to judge, before it asks (D26).
  if job.world.accessibility ~= true then refuse(ACCESSIBILITY) end
  local nxt, err, fix = plan_then(job, "prepare")
  if not nxt then refuse(err, fix) end
  return nxt
end

function PHASE.unseen(job)
  return waiting(job, "unseen", UNSEEN_SECONDS, function(w) return retry_unseen(job, w) end, job.after_unseen)
end

-- Step 6's refusals, then the creates (step 7). First, before anything
-- changes: a plan that leaves an entry unseen while Hammerspoon's window
-- filter failed asks the CLI to reload Hammerspoon and run apply again, when
-- the request lets it (ST6d8eed9 WP a45b3aeb). The unseen wait has given the
-- filter its chance to come back by then.
function PHASE.prepare(job)
  local reload = P.reload_reason(job.ops, job.request_options.may_reload)
  if reload then error({ reload = reload }, 0) end
  local ctx = { hand = new_hand(), unmoved = {}, world = job.world, world_before = job.world, lg = job.lg }
  ctx.keys, ctx.keys_error = move_keys()
  if P.needs_hand(job.ops, job.world) then
    if not ctx.keys then refuse(ctx.keys_error) end
    local free, why = hands_free()
    if not free then refuse(why) end
  end
  job.ctx = ctx
  job.first_ops = job.ops
  job.changed = true
  job.creates = only(job.ops, { create_space = true })
  if #job.creates > 0 then
    append(job.results, M.execute(job.creates, ctx))
    return "created", POLL_SECONDS
  end
  return "organise_start"
end

-- After the creates, one fresh read of the world for the replan, tried again
-- through a read that fails for up to 3 s (WP 93ea7f8a). Nothing is waited for
-- beyond that read: each create is done only once its own count readback
-- lists the new desktop (exec_create_space), and com.apple.spaces, which macOS
-- may not write before the next display change, is never waited on. The read
-- is logged, so the run log shows the record after the creates.
function PHASE.created(job)
  return waiting(job, "created", 3, function(w)
    job.world = w
    return true
  end, "replan", true)
end

-- Step 9: plan again against the fresh world, for move and place. apply
-- launches nothing (ST6d8eed9 WP 35219619), so the replan follows only the
-- creates.
function PHASE.replan(job)
  job.options = {
    no_create = true, after_create = #job.creates > 0, user_no_create = job.request_options.no_create,
    map = job.request_options.map, own_sizes = job.request_options.own_sizes,
    running_before = P.running_set(job.ctx.world_before),
    -- The windows named at the start, by app, against which a read that says
    -- an app is not running is set (STca1b7f9 WP6).
    windows_before = P.app_windows(job.ctx.world_before),
    after_reload = job.request_options.after_reload_of ~= nil,
  }
  local nxt, err = plan_then(job, "organise_start")
  if not nxt then error("the plan after creating refused: " .. tostring(err), 0) end
  return nxt
end

-- Step 10: everything but what ran already, one op per callback. A kind this
-- does not know reaches execute, which fails it out loud.
function PHASE.organise_start(job)
  local ctx = job.ctx
  ctx.world = job.world
  -- Each display by the desk's name for it, else its own, for a step's `via`
  -- and a failed move's words (STca1b7f9).
  ctx.names = P.display_names(job.desk, ctx.world, job.options)
  job.rest = except(job.ops, { create_space = true })
  job.next_op = 1
  if P.needs_hand(job.rest, ctx.world) then
    local took, why = take_hand(ctx)
    if not took then ctx.stopped = why end
  end
  if #job.rest == 0 then return "finish" end
  return "organise"
end

-- THE PAUSE (hv decision 26, ST6d8eed9 WP 4cb617e2). When the person takes
-- the pointer during an op's legs, the hand lets go at once (run_legs), and
-- the run pauses: `still` reads the pointer on a timer until it is still,
-- then the op runs again from the start, planned from where its window is
-- now. A pause that gives up, and a take after MAX_PAUSES pauses, end the
-- moves as a take did before pauses: the op fails, and every move after it
-- is not tried.

-- The moves end: CTX says so to every move after this one, and each result
-- of the op the pointer was taken from fails with the take's words, WHY, and
-- the way out.
local function moves_end(ctx, results, taken, why)
  ctx.stopped = "the pointer was taken back during an earlier move (" .. taken .. ")"
  for _, r in ipairs(results) do
    if r.status ~= "done" then
      r.reason = tostring(r.reason) .. "; " .. why
      r.fix = P.PAUSE_FIX
    end
  end
end

-- A pause begins after op INDEX of job.rest gave RESULTS: kept, for a pause
-- that gives up, with the op's step number, so its step goes out again under
-- the same one.
local function pause_began(job, index, results)
  job.pauses = (job.pauses or 0) + 1
  job.pause = { index = index, i = job.step_i, taken = job.ctx.taken, results = results,
    began = hs.timer.secondsSinceEpoch() }
  note(job.lg, "pause", string.format("pause %d of %d: %s", job.pauses, P.MAX_PAUSES, job.ctx.taken))
  wait_began(job, "still", P.PAUSE_LIMIT, { still = P.STILL_SECONDS })
  return "still", POLL_SECONDS
end

-- An op that ran again after pauses and took says how long it paused.
local function resumed_note(job, results)
  if not job.resumed then return end
  for _, r in ipairs(results) do
    if r.status == "done" then
      local said = P.paused_note(job.resumed)
      r.note = r.note and (r.note .. "; " .. said) or said
    end
  end
  job.resumed = nil
end

function PHASE.organise(job)
  local ctx = job.ctx
  local index = job.next_op
  job.next_op = index + 1
  ctx.taken = nil
  local results = M.execute({ job.rest[index] }, ctx)
  if ctx.taken then
    if (job.pauses or 0) < P.MAX_PAUSES then return pause_began(job, index, results) end
    moves_end(ctx, results, ctx.taken, P.PAUSES_SPENT)
  end
  resumed_note(job, results)
  append(job.results, results)
  if job.next_op > #job.rest then return "finish" end
  return "organise"
end

-- The pause: the pointer read every POLL_SECONDS on a timer, so Hammerspoon's
-- run loop turns and the toast can show it. Once it is still, the person may
-- have switched a desktop and the release left the window where it was, so
-- each display's shown desktop is read again, the hand is a fresh one, whose
-- last point is where the pointer is now, and the op runs again.
function PHASE.still(job)
  local pause, ctx = job.pause, job.ctx
  local t = hs.timer.secondsSinceEpoch()
  local verdict, look = P.still_verdict(t, pause.look, hs.mouse.absolutePosition(), hands_free() == true, pause.began)
  pause.look = look
  if verdict == "wait" then return "still", POLL_SECONDS end
  job.pause = nil
  if verdict == "still" then
    wait_ended(job, "still", "done")
    ctx.hand = new_hand()
    local took, why = take_hand(ctx)
    if took then
      local op = job.rest[pause.index]
      -- Its move is tried again, so a place of its window may run after it.
      if op.window then ctx.unmoved[op.window] = nil end
      job.next_op, job.step_i = pause.index, (pause.i or 1) - 1
      job.resumed = (job.resumed or 0) + (t - pause.began)
      return "organise"
    end
    moves_end(ctx, pause.results, pause.taken, why)
  else
    wait_ended(job, "still", "timed out")
    moves_end(ctx, pause.results, pause.taken, P.PAUSE_GAVE_UP)
  end
  job.resumed = nil
  append(job.results, pause.results)
  if job.next_op > #job.rest then return "finish" end
  return "organise"
end

-- Step 11: the pointer and focus given back, a last observe, the report.
function PHASE.finish(job)
  if job.ctx then give_back(job.ctx, job.results) end
  local final_ok, final = pcall(M.observe, job.bundles)
  if not final_ok then
    job.results[#job.results + 1] = { op = "final_observe", status = "failed", reason = tostring(final) }
    final = nil
  end
  local lines, code, tally = P.apply_report(job.desk, job.results)
  log_world(job.lg, "end", final)
  write_log(job.lg, "engine", function() return L.report_pairs(lines, code, tally) end)
  local own_sizes, changed = P.own_sizes_after(job.request_options.own_sizes, job.results)
  -- A read after the changes that failed the filter and left an entry unseen
  -- asks the CLI to reload and run apply again (ST6d8eed9 WP a45b3aeb), and
  -- the answer says how many times the run paused for the pointer (WP
  -- 4cb617e2).
  job.answer({ ops = job.first_ops, results = job.results, report = lines, exit = code, world = final,
    own_sizes = own_sizes, own_sizes_changed = changed, tally = tally,
    reload = P.reload_reason(job.ops, job.request_options.may_reload), paused = job.pauses or 0 })
end

-- The error response for a verb that raised: refused (nothing changed), a
-- reload asked for before anything changed (ST6d8eed9 WP a45b3aeb), or a Lua
-- error, for the CLI (D25).
local function error_response(verb, err)
  if type(err) == "table" and err.refused then
    return { status = "error", kind = "refused", verb = verb, error = tostring(err.refused), fix = err.fix }
  end
  if type(err) == "table" and err.reload then
    return { status = "error", kind = "reload", verb = verb, error = tostring(err.reload),
      fix = "arngz reloads Hammerspoon's config and runs it again" }
  end
  return { status = "error", kind = "lua_error", verb = verb, error = tostring(err) }
end

-- An error after things changed, answered with what was done so far, so the
-- kept response still says it.
local function failed_after_change(job, err)
  local out = error_response("apply", err)
  out.results = job.results
  out.paused = job.pauses or 0
  -- What it read back still counts: the CLI keeps the records it returns.
  out.own_sizes, out.own_sizes_changed = P.own_sizes_after(job.request_options.own_sizes, job.results)
  return out
end

-- The least time between phases. Chained at 0, the timer port is always
-- ready, the run loop never waits long enough to take hs.ipc's message, and a
-- read or a second apply queued until apply ended (vc's hands-off re-run at
-- 45acc46: a diff sent 1.5 s into a 13 s apply was answered at 9.5 s).
local PHASE_GAP = 0.05

-- Run one phase, then schedule the next.
local run_phase

-- A phase's callback: whatever raises here still answers, because an apply
-- that never answers leaves arngz_running set and refuses every apply after
-- it until Hammerspoon's config is reloaded.
local function guarded(job, name)
  local ok, err = pcall(run_phase, job, name)
  if not ok then job.respond(job.changed and failed_after_change(job, err) or error_response("apply", err)) end
end

-- Schedule a phase at least PHASE_GAP away, holding the timer in a global so
-- it is not collected before it fires (dc, D20). True, or nil and why.
local function schedule(job, name, delay)
  local scheduled, timer = pcall(hs.timer.doAfter, math.max(delay or 0, PHASE_GAP), function() guarded(job, name) end)
  if not scheduled then return nil, timer end
  rawset(_G, "arngz_timer", timer)
  return true
end

-- A phase in the run log as it starts, with how long the one before took. A
-- wait runs its phase again every POLL_SECONDS, and is logged once, by
-- waiting().
local function phase_began(job, name)
  if not (job.lg and job.lg.path) or job.phase_name == name then return end
  local t = now()
  local took = job.phase_at and string.format("; %s took %d ms", job.phase_name, math.floor((t - job.phase_at) / 1e6)) or ""
  job.phase_at, job.phase_name = t, name
  note(job.lg, "phase", name .. took)
end

-- A step point stands for an op execute performs (EXEC), so a kind added
-- there gets its step without a second list to keep in step.
local function steps_total(job)
  local n = 0
  local function count(ops)
    for _, op in ipairs(ops or {}) do
      if EXEC[op.op] then n = n + 1 end
    end
  end
  if job.rest then
    count(job.creates)
    count(job.rest)
  else
    count(job.ops)
  end
  return n
end

-- THE STEP POINTS GO OUT BEFORE THEIR WORK (progress.md, rule 2): Hammerspoon
-- draws only between callbacks, so each is emitted here, before the callback
-- that does it is scheduled. prepare's creates run as one batch, so their
-- steps all go out before it. A move's step carries
-- the window's frame now, for the toast to keep clear of the grab, and the
-- display it goes round through, if it does (STca1b7f9 WP3). A point that
-- cannot be made is an error record, never a failed run.
local function steps_before(job, nxt)
  local batch
  if nxt == "prepare" then
    batch = only(job.ops, { create_space = true })
  elseif nxt == "organise" then
    local op = job.rest and job.rest[job.next_op]
    batch = (op and EXEC[op.op]) and { op } or {}
  else
    return
  end
  local ok, err = pcall(function()
    for _, op in ipairs(batch or {}) do
      job.step_i = (job.step_i or 0) + 1
      local frame, via
      if op.op == "move" then
        local w = hs.window.get(op.window)
        frame = w and rect(w:frame())
        via = step_via(op, job.ctx)
      end
      point(job.lg, "step", L.step_fields(job.desk, op, job.step_i, steps_total(job), frame, via))
    end
  end)
  if not ok then note(job.lg, "error", "a step point could not be made: " .. tostring(err)) end
end

run_phase = function(job, name)
  phase_began(job, name)
  local ok, nxt, delay = pcall(PHASE[name], job)
  if not ok then
    if not job.changed then return job.respond(error_response("apply", nxt)) end
    if name == "finish" then return job.respond(failed_after_change(job, nxt)) end
    job.results[#job.results + 1] = { op = "phase", phase = name, status = "failed", reason = name .. ": " .. tostring(nxt) }
    nxt, delay = "finish", 0
  end
  if not nxt then return end
  steps_before(job, nxt)
  local scheduled, serr = schedule(job, nxt, delay)
  if scheduled then return end
  local why = "could not schedule the " .. nxt .. " phase: " .. tostring(serr)
  if not job.changed then return job.respond(error_response("apply", { refused = why })) end
  job.results[#job.results + 1] = { op = "phase", phase = nxt, status = "failed", reason = why }
  -- finish runs here instead, and answers: it schedules nothing.
  return run_phase(job, "finish")
end

-- Start apply: its first phase is scheduled, and respond(response) is called
-- once, by the phase that answers. True, or nil and why nothing was
-- scheduled.
function M.start_apply(desk, options, respond, lg)
  if type(desk) ~= "table" then return nil, "apply needs the desk" end
  options = options or {}
  local job = {
    desk = desk, request_options = options, results = {},
    options = { no_create = options.no_create, map = options.map, own_sizes = options.own_sizes,
      after_reload = options.after_reload_of ~= nil },
    deadlines = {}, observed = {}, observe_errors = {}, changed = false,
    -- The run's log (ST589246c); with none, no record is written.
    lg = lg or new_log({}),
  }
  -- Answered once: a second answer would write over the first.
  job.respond = function(response)
    if job.responded then return end
    job.responded = true
    respond(response)
  end
  job.answer = function(out)
    out.status, out.verb = "ok", "apply"
    job.respond(out)
  end
  local scheduled, serr = schedule(job, "quiet", 0)
  if not scheduled then return nil, "could not schedule apply: " .. tostring(serr) end
  return true
end

-- ---------------------------------------------------------------- the contract

-- The engine's verbs. Each answers with what its caller renders -- for
-- observe, the world as it is, which the hand-run acceptance reads; the CLI
-- has no observe verb -- so nothing downstream recomputes (design.md, "The
-- engine").
-- A refusal from a pure function travels back as a refusal raised here,
-- which answer() turns into an error response of kind "refused".
-- Each verb takes the run's log third, and records the displays it read and
-- the observed point (ST589246c); nothing else in it changes for the log.
local function observed(lg, world)
  log_world(lg, "start", world)
  point(lg, "observed", function() return L.observed_fields(world) end)
  return world
end

local VERBS = {
  observe = function(_, _, lg)
    local world = observed(lg, M.observe())
    return { world = world }
  end,
  -- which: the desk the screens present are (ST0032/04). options.desks, a
  -- list of { name, desk } in the catalogue's order, and options.current.
  -- It answers ok even when no desk fits, rather than refusing: the exit code
  -- is the CLI's to choose and arngz keeps every exit there, and a refusal
  -- would collapse "none fits" and "several fit" into one kind. M.observe is
  -- reused whole, though only the screens are needed, because world.screens
  -- has one builder and a second could drift from what match_displays expects.
  which = function(_, options, lg)
    local world = observed(lg, M.observe())
    local name, kind, report, candidates =
      P.detect(options.desks or {}, world, { current = options.current })
    return { desk = name, kind = kind, candidates = candidates, report = report }
  end,
  -- discover: the world as a desk (WP-04). options.grid, options.name.
  -- A read whose window filter failed is never a desk: it would leave out the
  -- windows on desktops not shown, and --save --force writes the whole desk.
  -- When the request lets it, the answer asks the CLI to reload Hammerspoon
  -- and ask again (ST6d8eed9 WP a45b3aeb); otherwise it is refused.
  discover = function(_, options, lg)
    local world = observed(lg, M.observe())
    if P.filter_failed(world) then
      local why = P.filter_words(world)
      if options.may_reload then error({ reload = why }, 0) end
      refuse(why .. ", so windows on desktops not shown could not be named, and a desk read now would leave them out",
        options.after_reload_of and P.FILTER_FIX_AFTER_RELOAD or P.FILTER_FIX)
    end
    local desk, notes, fix = P.desk_from_world(world, { grid = options.grid, name = options.name })
    if not desk then refuse(notes, fix) end
    return { desk = desk, report = notes }
  end,
  -- plan: what apply would do, and nothing done (diff, and apply --dry-run).
  -- execute is never called on this path.
  plan = function(desk, options, lg)
    if type(desk) ~= "table" then refuse("plan needs the desk") end
    local ops, err, fix = plan_settled(desk, observed(lg, M.observe(P.desk_bundles(desk))), options)
    if not ops then
      point(lg, "planned", function() return L.planned_fields(nil, err) end)
      refuse(err, fix)
    end
    local report = P.plan_report(ops)
    write_log(lg, "engine", function() return L.plan_pairs(ops, report) end)
    point(lg, "planned", function() return L.planned_fields(ops) end)
    return { ops = ops, report = report, exit = P.plan_exit(ops) }
  end,
  -- reload (ST6d8eed9 WP a45b3aeb): Hammerspoon's config reloaded, on a timer
  -- after this answer is written, since a reload ends the Lua state the answer
  -- comes from. Refused while an apply runs, which a reload would end mid-run.
  -- Until the reload, arngz_running holds a new apply off and arngz_reloading
  -- says that the old state answers; a fresh state has neither (`state`).
  reload = function()
    local running = rawget(_G, "arngz_running")
    if running then
      refuse(string.format("%s is running (asked for at %s)", a_run(running), tostring(running.at)),
        "another arngz run is live; run it again when it has finished")
    end
    rawset(_G, "arngz_running", { verb = "reload", at = utc_now() })
    rawset(_G, "arngz_reloading", true)
    rawset(_G, "arngz_reload_timer", hs.timer.doAfter(RELOAD_DELAY, hs.reload))
    return { reloading = true }
  end,
  -- state: whether a reload asked for is still to come. The CLI asks it until
  -- a fresh Lua state answers (ST6d8eed9 WP a45b3aeb).
  state = function()
    return { reloading = rawget(_G, "arngz_reloading") == true }
  end,
}

-- Verbs that run longer than the hs client waits (4 s, D20 as amended):
-- scheduled on a timer, the IPC call returning at once, the response file the
-- only answer. THE SAME LIST AS SCHEDULED_VERBS in opt/arngz/arngz, which
-- arngz.bats holds the two to. Each starts with START[verb].
local SCHEDULED = { apply = true }
local START = { apply = M.start_apply }

-- The response, written aside and renamed, so it appears whole or not at all.
-- The CLI treats the file's appearance as the answer, and does not wait for
-- hs to return: measured 16 Oct 2026, hs -c sometimes never returns after
-- run() has finished and written its response, -t notwithstanding.
local function respond(response_path, response)
  local partial = response_path .. ".partial"
  -- A failure here leaves no response, so it is said on the console too: in
  -- the measured case where hs never returns, the return line is never read.
  local wrote_ok, wrote = pcall(hs.json.write, response, partial, true, true)
  if not wrote_ok or not wrote then
    local why = "could not write " .. partial .. (wrote_ok and "" or (": " .. tostring(wrote)))
    print("arngz: error: " .. why)
    return "arngz: error: " .. why
  end
  local renamed, rerr = os.rename(partial, response_path)
  if not renamed then
    print("arngz: error: could not rename " .. partial .. ": " .. tostring(rerr))
    return "arngz: error: could not rename " .. partial .. ": " .. tostring(rerr)
  end
  return "arngz: " .. response.status .. " " .. tostring(response.verb)
end

-- The verb's answer, or an error response whose kind says whether the engine
-- refused (nothing changed) or failed (a Lua error), for the CLI (D25).
local function answer(request, lg)
  local ok, out = pcall(VERBS[request.verb], request.desk, request.options or {}, lg)
  if not ok then return error_response(request.verb, out) end
  out.status = "ok"
  out.verb = request.verb
  return out
end

-- A run's start (ST589246c): its record, the toast hook's state, and the
-- start point (progress.md).
local function begin_run(lg, request)
  local desk = type(request.desk) == "table" and request.desk.desk
    or (type(request.options) == "table" and request.options.name) or ""
  note(lg, "start", function()
    return string.format("%s %s; options %s; toasts %s", tostring(request.verb), tostring(desk),
      L.options_text(request.options),
      M.toast and "on" or (M.toast_error and ("off: " .. M.toast_error) or "off: there is no toast.lua"))
  end)
  if M.toast_error then lg.toast_error = lg.toast_error or M.toast_error end
  -- A retry after a reload says which run it retries (ST6d8eed9 WP a45b3aeb).
  local again = type(request.options) == "table" and request.options.after_reload_of or nil
  point(lg, "start", { verb = tostring(request.verb), desk = tostring(desk),
    after_reload_of = again ~= nil and tostring(again) or nil })
end

-- What the log and the toast hook could not do, put in RESPONSE for the CLI
-- to say once, then the response written. One line each: the CLI reads the
-- two as two lines.
local function respond_with(response_path, response, lg)
  if lg.failures > 0 then
    response.log_error = (string.format("%s (%d write(s) failed)", tostring(lg.first_failure), lg.failures)
      :gsub("%c", " "))
  end
  if lg.toast_error then response.toast_error = (tostring(lg.toast_error):gsub("%c", " ")) end
  return respond(response_path, response)
end

-- A run's end (progress.md, rule 3): the finished point, from the response,
-- whatever it says; then the response, with what the log and the toast hook
-- could not do. Every path that answers a request comes through here, once,
-- but the quiet gate's `unsettled`, which ends nothing (M.run).
local function finish_run(response_path, response, lg)
  local clocked, t = pcall(function() return hs.timer.secondsSinceEpoch() end)
  local seconds = (clocked and lg.started) and math.floor((t - lg.started) * 10 + 0.5) / 10 or 0
  if response.status ~= "ok" then
    -- A refusal, or a reload asked for (ST6d8eed9 WP a45b3aeb), under its own
    -- kind; anything else is an error.
    local event = (response.kind == "refused" or response.kind == "reload") and response.kind or "error"
    note(lg, event, tostring(response.error) .. (response.fix and ("; fix: " .. tostring(response.fix)) or ""))
  end
  point(lg, "finished", function() return L.finished_fields(response, seconds, lg.path) end)
  return respond_with(response_path, response, lg)
end

-- The quiet gate (WP 93ea7f8a). auto's which and discover --save act on what
-- they read, so their requests carry options.quiet, and they read nothing
-- until the displays have settled (P.quiet_verdict). Until then the answer
-- is `unsettled`, saying how long to wait and when the wait began, with no
-- point and no run begun: the CLI sleeps, never Hammerspoon, and asks again
-- under the same run with that began. Past the limit the run refuses, with
-- its start and finished, and a gate that raises answers as a verb's own
-- error does. apply waits in its own phase instead. Returns the written
-- status line when the gate answers, or nil when the verb is to run.
local function quiet_answer(request, lg, response_path)
  local quiet = type(request.options) == "table" and request.options.quiet
  if type(quiet) ~= "table" or SCHEDULED[request.verb] then return nil end
  local ok, verdict, a, b, began = pcall(function()
    local t = hs.timer.secondsSinceEpoch()
    local from = tonumber(quiet.began) or t
    local v, x, y = P.quiet_verdict(t, rawget(_G, "arngz_screens"), from)
    return v, x, y, from
  end)
  if ok and verdict == "go" then return nil end
  if ok and verdict == "wait" then
    note(lg, "quiet", string.format("%s: the displays have not settled; the CLI waits %.1f s and asks again",
      tostring(request.verb), a))
    -- As strings, so the CLI hands back exactly what it was given.
    return respond_with(response_path, { status = "ok", verb = request.verb,
      unsettled = { wait = string.format("%.1f", a), began = string.format("%.3f", began) } }, lg)
  end
  begin_run(lg, request)
  if not ok then return finish_run(response_path, error_response(request.verb, verdict), lg) end
  return finish_run(response_path, { status = "error", kind = "refused", verb = request.verb, error = a, fix = b }, lg)
end

-- The IPC entry. Reads {verb, desk, options} from request_path, writes the
-- response to response.json beside it, and returns one status line. A failure
-- inside run is a response too; a failure loading this module surfaces through
-- hs's exit code and output, which the CLI names.
function M.run(request_path)
  if type(request_path) ~= "string" or request_path == "" then
    -- No path, so no response can be written: said on the console too.
    local line = "arngz: error: run needs the request file's path, and was given " .. tostring(request_path)
    print(line)
    return line
  end
  local response_path = (dirname(request_path) or ".") .. "/response.json"
  local read_ok, request = pcall(hs.json.read, request_path)
  if not read_ok then
    return respond(response_path, { status = "error", kind = "refused",
      error = "cannot read the request at " .. tostring(request_path) .. ": " .. tostring(request) })
  elseif type(request) ~= "table" then
    return respond(response_path, { status = "error", kind = "refused", error = "cannot read the request at " .. tostring(request_path)
      .. ": hs.json.read returned nothing, so it is missing or not JSON" })
  end
  -- From here the request names its run and its log (ST589246c), and every
  -- answer goes through finish_run, but the quiet gate's unsettled.
  local lg = new_log(request)
  M.watch(lg)
  local gated = quiet_answer(request, lg, response_path)
  if gated then return gated end
  begin_run(lg, request)
  if not (VERBS[request.verb] or SCHEDULED[request.verb]) then
    return finish_run(response_path, { status = "error", kind = "refused", verb = request.verb,
      error = "the engine has no verb " .. tostring(request.verb) }, lg)
  end
  if not SCHEDULED[request.verb] then return finish_run(response_path, answer(request, lg), lg) end

  -- One at a time: two applies would take the one pointer from each other.
  -- apply spans timer callbacks, so a second request reaches the engine
  -- between the first's phases and is refused here; one that arrives as the
  -- last phase ends runs after it (dc). The state lives in globals because
  -- dofile makes this module anew at every call (dc, D20).
  local running = rawget(_G, "arngz_running")
  if running then
    -- Its own start and finished, under its own run, so its toast leaves the
    -- running one alone (progress.md, rule 3).
    return finish_run(response_path, { status = "error", kind = "refused", verb = request.verb,
      error = string.format("%s is already running (asked for at %s)", a_run(running), tostring(running.at)),
      fix = "wait for it to finish; if none is running, reload Hammerspoon's config (hs.reload() in its console),"
        .. " which clears what a crashed apply left set" }, lg)
  end
  rawset(_G, "arngz_running", { verb = request.verb, at = utc_now() })
  local function done(response)
    local ok, line = pcall(finish_run, response_path, response, lg)
    if not ok then print("arngz: error: " .. tostring(line)) end
    rawset(_G, "arngz_running", nil)
    rawset(_G, "arngz_timer", nil)
  end
  local called, started, why = pcall(START[request.verb], request.desk, request.options or {}, done, lg)
  if not called then started, why = nil, tostring(started) end
  if not started then
    -- Never left marked as running when nothing was scheduled.
    rawset(_G, "arngz_running", nil)
    return finish_run(response_path, { status = "error", kind = "refused", verb = request.verb, error = why }, lg)
  end
  return "arngz: scheduled " .. request.verb
end

return M
