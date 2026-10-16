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

local M = {}

-- A wait reads this often: a launch's, between phases, or inside the plan
-- verb's call.
local POLL_SECONDS = 0.25

-- How long launch waits for an app's first window (design.md, apply step 8).
M.LAUNCH_TIMEOUT = 20

-- ---------------------------------------------------------------- helpers

local function utc_now() return os.date("!%Y-%m-%dT%H:%M:%SZ") end

-- A refusal: raised as a tagged table, so answer() can tell "refused before
-- anything changed" from a Lua error inside the engine (D25).
local function refuse(why) error({ refused = why }, 0) end

local function rect(r)
  if not r then return nil end
  return { x = r.x, y = r.y, w = r.w, h = r.h }
end

local function shell_quote(s)
  return "'" .. (tostring(s):gsub("'", "'\\''")) .. "'"
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

-- The app's own bundle id for a desk's spelling of it. A desk names an app
-- whatever the case (design.md, "An app"), and applicationsForBundleID, which
-- hs.application.get uses, matches only the app's own case (measured 16 Oct
-- 2026: com.apple.Finder finds nothing, com.apple.finder finds Finder).
-- LaunchServices answers in any case. An app it does not know keeps the
-- desk's spelling, and launching it says it is not installed. A lookup that
-- raises is nil and why: could not see, never taken for not there.
local function own_id(bundle)
  local ok, info = pcall(hs.application.infoForBundleID, bundle)
  if not ok then return nil, "infoForBundleID(" .. tostring(bundle) .. "): " .. tostring(info) end
  if type(info) == "table" and type(info.CFBundleIdentifier) == "string" then return info.CFBundleIdentifier end
  return bundle
end

-- f() tried up to `times` times, a fifth of a second apart (never after the
-- last): true and its value, or false and the last error.
local function attempts(times, f)
  local ok, value
  for i = 1, times do
    ok, value = pcall(f)
    if ok then return true, value end
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
  if app then d.bundle = app:bundleID() end
  return d
end

-- ---------------------------------------------------------------- observe

-- The world as it is now. Read-only. Every lookup that can fail records its
-- error beside the value rather than dropping it, because "could not see" and
-- "is not there" need different answers. `bundles`, the desk's app bundle
-- ids, is what is asked about one by one, fresh, for whether it runs.
function M.observe(bundles)
  -- com.apple.spaces first: it holds each display's space order (D22) as
  -- well as the Dock bindings.
  local spaces_prefs, spaces_err = read_defaults("com.apple.spaces")
  local monitors = spaces_prefs and spaces_prefs.SpacesDisplayConfiguration
    and spaces_prefs.SpacesDisplayConfiguration["Management Data"]
    and spaces_prefs.SpacesDisplayConfiguration["Management Data"].Monitors
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
    screens = {},
    apps_running = {},
    app_bindings = {},
  }

  for _, scr in ipairs(hs.screen.allScreens()) do
    local uuid = scr:getUUID()
    local full = rect(scr:fullFrame())
    local active, aerr = hs.spaces.activeSpaceOnScreen(uuid)
    local entry = {
      uuid = uuid,
      name = scr:name(),
      primary = uuid == primary:getUUID(),
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
    -- Mission Control's order is com.apple.spaces', not the live list's
    -- (D22, measured 16 Oct 2026). Without it the spaces are still recorded,
    -- in the live order, and order_error says why: plan refuses that.
    local ordered = spaces
    if spaces then
      if monitors then
        local oerr
        ordered, oerr = P.order_spaces(spaces, monitors)
        if not ordered then
          ordered = spaces
          entry.order_error = oerr
        end
      else
        entry.order_error = "com.apple.spaces carries no display configuration"
          .. (spaces_err and (": " .. spaces_err) or "")
      end
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

-- ---------------------------------------------------------------- execute

-- How many desktops a screen has, or nil and why it could not be read, so a
-- failed readback is never blamed on the op it was reading back.
local function user_space_count(uuid)
  local spaces, err = hs.spaces.spacesForScreen(uuid)
  if not spaces then return nil, "spacesForScreen: " .. tostring(err) end
  local n = 0
  for _, id in ipairs(spaces) do
    local stype, terr = hs.spaces.spaceType(id)
    if stype == nil then return nil, "spaceType(" .. tostring(id) .. "): " .. tostring(terr) end
    if P.is_user_space(stype) then n = n + 1 end
  end
  return n
end

local function exec_create_space(op)
  local before, berr = user_space_count(op.screen)
  if not before then return { status = "failed", reason = "could not count the desktops before: " .. berr } end
  local ok, err = hs.spaces.addSpaceToScreen(op.screen, true)
  local after, aerr = user_space_count(op.screen)
  if not after then
    return { status = "failed", reason = string.format("addSpaceToScreen returned %s; could not read back: %s",
      tostring(ok), aerr) }
  end
  if ok and after == before + 1 then
    return { status = "done", readback = { user_spaces = after } }
  end
  return { status = "failed", reason = string.format("addSpaceToScreen returned %s%s; user spaces %d before, %d after",
    tostring(ok), err and (" (" .. tostring(err) .. ")") or "", before, after) }
end

-- A window plan could claim (named, standard, not minimized): what a launch
-- waits for, because a splash or a palette is not what the desk places.
local function claimable_window(bundle)
  local id, why = own_id(bundle)
  if not id then error(why, 0) end
  local app = hs.application.get(id)
  if not app then return nil end
  for _, w in ipairs(app:allWindows() or {}) do
    if P.claimable({ named = true, standard = w:isStandard(), minimized = w:isMinimized() }) then return w end
  end
  return nil
end

local function exec_launch(op)
  local out, ok, _, rc = hs.execute("/usr/bin/open -b " .. shell_quote(op.bundle) .. " 2>&1")
  local status, reason = P.launch_verdict(ok, out, rc)
  if status then return { status = status, reason = reason } end
  local waited = 0
  while waited < M.LAUNCH_TIMEOUT do
    local w = claimable_window(op.bundle)
    if w then return { status = "done", readback = { window = w:id(), waited = waited } } end
    hs.timer.usleep(math.floor(POLL_SECONDS * 1e6))
    waited = waited + POLL_SECONDS
  end
  return { status = "failed", reason = string.format("launched, but no standard window within %d s", M.LAUNCH_TIMEOUT) }
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
  if P.frames_agree(got, op.frame) then
    return { status = "done", readback = { frame = got } }
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
-- taken: a click on a document window's title opens a rename popover.
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
  if GRAB_ROLES[role] then return "grab" end
  return "a control (" .. tostring(role) .. ")"
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
      local verdict = hit_test(p, id, pid)
      if verdict == "grab" then return { point = p, frame = frame } end
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
-- move), and the active spaces read live.
local function now_state(world)
  local state = { order = {}, types = {}, active = {}, active_error = {}, screens = {} }
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

function LEG.carry(ctx, leg, id)
  local g, why = held_point(id)
  if not g then return why end
  local hand = ctx.hand
  hand:press(g.point)
  hand:drag({ { x = g.point.x + (leg.side == "right" and NUDGE_PX or -NUDGE_PX), y = g.point.y } })
  hand:hold(0.1, "before the keys")
  for _, step in ipairs(leg.steps) do
    press_key(ctx.keys[leg.side])
    local took = wait_for(hand, STEP_WAIT, "while holding the window", function()
      local spaces = list(hs.spaces.windowSpaces(id))
      return #spaces == 1 and spaces[1] == step and hs.spaces.activeSpaceOnScreen(leg.screen) == step
    end)
    if not took then
      hand:release()
      local spaces, serr = hs.spaces.windowSpaces(id)
      local at, aerr = hs.spaces.activeSpaceOnScreen(leg.screen)
      return string.format("held and pressed Move-space %s, and after %d s the window is on %s, not space %s alone,"
        .. " and screen %s shows %s", leg.side, STEP_WAIT,
        spaces and ("{" .. table.concat(list(spaces), ",") .. "}") or ("what could not be read: " .. tostring(serr)),
        tostring(step), tostring(leg.screen), at and ("space " .. tostring(at)) or ("what could not be read: " .. tostring(aerr)))
    end
  end
  hand:hold(0.15, "before letting go")
  hand:release()
  return nil
end

-- Held: dragged over the shared edges onto the target display's shown space.
function LEG.drag(ctx, leg, id)
  local chain = P.route(ctx.state.screens, leg.from_screen, leg.screen)
  if not chain then
    return "no chain of shared edges joins screen " .. tostring(leg.from_screen) .. " to " .. tostring(leg.screen)
  end
  local g, why = held_point(id)
  if not g then return why end
  local dest = P.drop_point(g.point, g.frame, chain[#chain])
  local hand = ctx.hand
  hand:press(g.point)
  hand:drag(P.path(chain, g.point, dest))
  hand:hold(0.2, "before letting go")
  hand:release()
  return nil
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
-- when they all took, or why not; a stop marks ctx.stopped for every move
-- after this one.
local function run_legs(ctx, legs, id)
  for _, leg in ipairs(legs) do
    local ok, err = pcall(LEG[leg.kind], ctx, leg, id)
    if not ok then
      local released, rerr = pcall(function() ctx.hand:release() end)
      local note = released and "" or ("; and letting go of the button failed: " .. tostring(rerr))
      if type(err) == "table" and err.stop then
        ctx.stopped = "the pointer was taken back during an earlier move (" .. err.stop .. ")"
        return "stopped: " .. err.stop .. note
      end
      return "lua error in the " .. leg.kind .. " leg: " .. tostring(err) .. note
    end
    if err then return leg.kind .. ": " .. err end
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

local function exec_move(op, ctx)
  if ctx.stopped then
    return { status = "failed", reason = "not tried: " .. ctx.stopped }
  end
  if not ctx.keys then
    return { status = "failed", reason = "not tried: " .. tostring(ctx.keys_error) }
  end
  local home, herr = window_home(op.window)
  if not home then return { status = "failed", reason = herr } end
  local legs, why = P.move_legs(ctx.state, {
    screen = op.screen, space = op.space, ordinal = op.ordinal, from_screen = home.screen, from_space = home.space,
  })
  if not legs then return { status = "failed", reason = why } end
  local failed = run_legs(ctx, legs, op.window)
  if failed then return { status = "failed", reason = failed } end
  -- The readback (design.md, "Moving a window"): a gesture has no return
  -- value, so this is the only evidence the move happened.
  if #legs > 0 then pause(0.5) end
  local rb = move_readback(op, home.space)
  local status, reason = P.move_verdict(rb, op, #legs > 0)
  return { status = status, reason = reason, readback = rb }
end

-- Ops that ask for nothing to be done, and the status the report gives them.
local REPORT_ONLY = { unseen = "unseen", not_launched = "skipped", gone = "failed", unmovable = "failed", no_space = "failed" }

local EXEC = { create_space = exec_create_space, launch = exec_launch, move = exec_move, place = exec_place }

-- Perform each op in order and read back after each one (D14). Nothing is
-- reported done that the readback does not show. ctx carries the hand, the
-- Move-space keys and where things are, for the moves.
function M.execute(ops, ctx)
  ctx = ctx or {}
  ctx.unmoved = ctx.unmoved or {}
  local results = {}
  for i, op in ipairs(ops or {}) do
    local r
    if REPORT_ONLY[op.op] then
      r = { status = REPORT_ONLY[op.op], reason = op.reason }
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
    results[#results + 1] = r
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

-- After create_space: com.apple.spaces has caught up with the live list
-- (design.md, apply 7).
local function spaces_agree(world)
  for _, s in ipairs(world.screens or {}) do
    if s.order_error then return false end
  end
  return true
end

-- A plan that finds an entry unseen is planned again from fresh observes for
-- up to this long: a window on a desktop its display is not showing is named
-- in one read and not the next (vc's hand run, 16 Oct 2026), so one read is
-- not taken as the answer.
local UNSEEN_SECONDS = 1.5

local function has_unseen(ops) return #only(ops, { unseen = true }) > 0 end

-- One retry of a plan that found an entry unseen, from WORLD. held carries
-- desk, options, and the ops and world in hand. The plan in hand is the last
-- one plan made from a world it could read: a retry plan refuses (a listing
-- that failed for a moment, which unread() refuses) does not replace it. A
-- crash in plan is raised, never taken for an unseen entry. True once
-- nothing is unseen.
local function retry_unseen(held, world)
  local o = P.plan(held.desk, world, held.options)
  if not o then return false end
  held.ops, held.world = o, world
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
-- entry is unseen, up to UNSEEN_SECONDS. Returns the ops and plan's refusal.
local function plan_settled(desk, world, options)
  local ops, err = P.plan(desk, world, options)
  if not (ops and has_unseen(ops)) then return ops, err end
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
local function waiting(job, name, seconds, done, next_phase, must_observe)
  job.deadlines[name] = job.deadlines[name] or (now() + seconds * 1e9)
  local ok, world = pcall(M.observe, job.bundles)
  if ok then
    job.observed[name] = true
    if done(world) then return next_phase end
  else
    job.observe_errors[name] = world
  end
  if now() < job.deadlines[name] then return name, POLL_SECONDS end
  if must_observe and not job.observed[name] then error("observe: " .. tostring(job.observe_errors[name]), 0) end
  return next_phase
end

-- Plan from job.world with job.options: the held plan, then a wait while an
-- entry is unseen, then `after`. A refusal is plan's err, for the caller.
local function plan_then(job, after)
  local ops, err = P.plan(job.desk, job.world, job.options)
  if not ops then return nil, err end
  job.ops, job.after_unseen = ops, after
  job.deadlines.unseen, job.observed.unseen, job.observe_errors.unseen = nil, nil, nil
  if has_unseen(ops) then return "unseen", POLL_SECONDS end
  return after
end

-- Step 5: observe, match, plan.
function PHASE.inventory(job)
  job.bundles = P.desk_bundles(job.desk)
  job.world = M.observe(job.bundles)
  -- Only Hammerspoon can say whether it holds the grant; the preferences are
  -- the CLI's to judge, before it asks (D26).
  if job.world.accessibility ~= true then refuse(ACCESSIBILITY) end
  local nxt, err = plan_then(job, "prepare")
  if not nxt then refuse(err) end
  return nxt
end

function PHASE.unseen(job)
  return waiting(job, "unseen", UNSEEN_SECONDS, function(w) return retry_unseen(job, w) end, job.after_unseen)
end

-- Step 6's refusals, then the creates (step 7).
function PHASE.prepare(job)
  local ctx = { hand = new_hand(), unmoved = {}, world = job.world, world_before = job.world, launched = {} }
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
  job.launches = only(job.ops, { launch = true })
  if #job.creates > 0 then
    append(job.results, M.execute(job.creates, ctx))
    return "created", POLL_SECONDS
  end
  if #job.launches > 0 then return "launch" end
  return "organise_start"
end

function PHASE.created(job)
  return waiting(job, "created", 3, function(w)
    job.world = w
    return spaces_agree(w)
  end, #job.launches > 0 and "launch" or "replan", true)
end

-- Step 8: each launch waits for a claimable window through the fresh query.
function PHASE.launch(job)
  local done = M.execute(job.launches, job.ctx)
  append(job.results, done)
  for _, r in ipairs(done) do job.ctx.launched[P.app_key(r.bundle)] = r.status == "done" end
  return "launched", POLL_SECONDS
end

-- Until every app whose launch was done runs and has a window plan could
-- claim named on a desktop, for up to the launch timeout. A launched window
-- becomes nameable a beat after the launch sees it (vc's hand runs, 16 Oct
-- 2026). Plan reports what is still not named as unseen.
function PHASE.launched(job)
  return waiting(job, "launched", M.LAUNCH_TIMEOUT, function(w)
    job.world = w
    return #P.unsettled_launches(w, job.ctx.launched) == 0
  end, "replan", true)
end

-- Step 9: plan again against the fresh world, for move and place.
function PHASE.replan(job)
  job.options = {
    no_create = true, after_create = #job.creates > 0, user_no_create = job.request_options.no_create,
    no_launch = job.request_options.no_launch, map = job.request_options.map,
    launched = job.ctx.launched, running_before = P.running_set(job.ctx.world_before),
  }
  local nxt, err = plan_then(job, "organise_start")
  if not nxt then error("the plan after creating and launching refused: " .. tostring(err), 0) end
  return nxt
end

-- Step 10: everything but what ran already, one op per callback. A kind this
-- does not know reaches execute, which fails it out loud.
function PHASE.organise_start(job)
  local ctx = job.ctx
  ctx.world = job.world
  job.rest = except(job.ops, { create_space = true, launch = true })
  job.next_op = 1
  if P.needs_hand(job.rest, ctx.world) then
    local took, why = take_hand(ctx)
    if not took then ctx.stopped = why end
  end
  if #job.rest == 0 then return "finish" end
  return "organise"
end

function PHASE.organise(job)
  local op = job.rest[job.next_op]
  job.next_op = job.next_op + 1
  append(job.results, M.execute({ op }, job.ctx))
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
  local lines, code = P.apply_report(job.desk, job.results)
  job.answer({ ops = job.first_ops, results = job.results, report = lines, exit = code, world = final })
end

-- The error response for a verb that raised: refused (nothing changed) or a
-- Lua error, for the CLI (D25).
local function error_response(verb, err)
  if type(err) == "table" and err.refused then
    return { status = "error", kind = "refused", verb = verb, error = tostring(err.refused) }
  end
  return { status = "error", kind = "lua_error", verb = verb, error = tostring(err) }
end

-- An error after things changed, answered with what was done so far, so the
-- kept response still says it.
local function failed_after_change(job, err)
  local out = error_response("apply", err)
  out.results = job.results
  return out
end

-- Run one phase, then schedule the next, holding the timer in a global so it
-- is not collected before it fires (dc, D20).
local run_phase

-- A phase's callback: whatever raises here still answers, because an apply
-- that never answers leaves arngz_running set and refuses every apply after
-- it until Hammerspoon's config is reloaded.
local function guarded(job, name)
  local ok, err = pcall(run_phase, job, name)
  if not ok then job.respond(job.changed and failed_after_change(job, err) or error_response("apply", err)) end
end

run_phase = function(job, name)
  local ok, nxt, delay = pcall(PHASE[name], job)
  if not ok then
    if not job.changed then return job.respond(error_response("apply", nxt)) end
    if name == "finish" then return job.respond(failed_after_change(job, nxt)) end
    job.results[#job.results + 1] = { op = "phase", phase = name, status = "failed", reason = name .. ": " .. tostring(nxt) }
    nxt, delay = "finish", 0
  end
  if not nxt then return end
  local scheduled, timer = pcall(hs.timer.doAfter, delay or 0, function() guarded(job, nxt) end)
  if scheduled then
    rawset(_G, "arngz_timer", timer)
    return
  end
  local why = "could not schedule the " .. nxt .. " phase: " .. tostring(timer)
  if not job.changed then return job.respond(error_response("apply", { refused = why })) end
  job.results[#job.results + 1] = { op = "phase", phase = nxt, status = "failed", reason = why }
  -- finish runs here instead, and answers: it schedules nothing.
  return run_phase(job, "finish")
end

-- Start apply: its first phase is scheduled, and respond(response) is called
-- once, by the phase that answers. True, or nil and why nothing was
-- scheduled.
function M.start_apply(desk, options, respond)
  if type(desk) ~= "table" then return nil, "apply needs the desk" end
  options = options or {}
  local job = {
    desk = desk, request_options = options, results = {},
    options = { no_create = options.no_create, no_launch = options.no_launch, map = options.map },
    deadlines = {}, observed = {}, observe_errors = {}, changed = false,
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
  local scheduled, timer = pcall(hs.timer.doAfter, 0, function() guarded(job, "inventory") end)
  if not scheduled then return nil, "could not schedule apply: " .. tostring(timer) end
  rawset(_G, "arngz_timer", timer)
  return true
end

-- ---------------------------------------------------------------- the contract

-- The engine's verbs. Each answers with what its caller renders -- for
-- observe, the world as it is, which the hand-run acceptance reads; the CLI
-- has no observe verb -- so nothing downstream recomputes (design.md, "The
-- engine").
-- A refusal from a pure function travels back as a refusal raised here,
-- which answer() turns into an error response of kind "refused".
local VERBS = {
  observe = function()
    local world = M.observe()
    return { world = world }
  end,
  -- discover: the world as a desk (WP-04). options.grid, options.name.
  discover = function(_, options)
    local world = M.observe()
    local desk, notes = P.desk_from_world(world, { grid = options.grid, name = options.name })
    if not desk then refuse(notes) end
    return { desk = desk, report = notes }
  end,
  -- plan: what apply would do, and nothing done (diff, and apply --dry-run).
  -- execute is never called on this path.
  plan = function(desk, options)
    if type(desk) ~= "table" then refuse("plan needs the desk") end
    local ops, err = plan_settled(desk, M.observe(P.desk_bundles(desk)), options)
    if not ops then refuse(err) end
    return { ops = ops, report = P.plan_report(ops) }
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
local function answer(request)
  local ok, out = pcall(VERBS[request.verb], request.desk, request.options or {})
  if not ok then return error_response(request.verb, out) end
  out.status = "ok"
  out.verb = request.verb
  return out
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
  elseif not (VERBS[request.verb] or SCHEDULED[request.verb]) then
    return respond(response_path, { status = "error", kind = "refused", verb = request.verb,
      error = "the engine has no verb " .. tostring(request.verb) })
  end
  if not SCHEDULED[request.verb] then return respond(response_path, answer(request)) end

  -- One at a time: two applies would take the one pointer from each other.
  -- apply spans timer callbacks, so a second request reaches the engine
  -- between the first's phases and is refused here; one that arrives as the
  -- last phase ends runs after it (dc). The state lives in globals because
  -- dofile makes this module anew at every call (dc, D20).
  local running = rawget(_G, "arngz_running")
  if running then
    return respond(response_path, { status = "error", kind = "refused", verb = request.verb,
      error = string.format("an %s is already running (asked for at %s)", running.verb, running.at),
      fix = "wait for it to finish; if none is running, reload Hammerspoon's config (hs.reload() in its console),"
        .. " which clears what a crashed apply left set" })
  end
  rawset(_G, "arngz_running", { verb = request.verb, at = utc_now() })
  local function done(response)
    local ok, line = pcall(respond, response_path, response)
    if not ok then print("arngz: error: " .. tostring(line)) end
    rawset(_G, "arngz_running", nil)
    rawset(_G, "arngz_timer", nil)
  end
  local called, started, why = pcall(START[request.verb], request.desk, request.options or {}, done)
  if not called then started, why = nil, tostring(started) end
  if not started then
    -- Never left marked as running when nothing was scheduled.
    rawset(_G, "arngz_running", nil)
    return respond(response_path, { status = "error", kind = "refused", verb = request.verb, error = why })
  end
  return "arngz: scheduled " .. request.verb
end

return M
