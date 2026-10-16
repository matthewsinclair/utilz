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

-- Every window Hammerspoon can NAME, by id. hs.window.allWindows sees only the
-- visible spaces; the default window filter is the documented route to
-- windows on the others (dc's spike). Which route named a window is kept.
--
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

-- A window can close, or not be backed yet, between Hammerspoon listing it and
-- reading it, and allWindows then raises from inside hs.axuielement (measured
-- by vc's hand run, 16 Oct 2026). So the listing is retried a few times, and
-- only a failure that persists is recorded, as could-not-read, never as no
-- windows.
local function nameable()
  local index = {}
  local listed, all = attempts(4, hs.window.allWindows)
  if not listed then
    return index, nil, "hs.window.allWindows failed four times: " .. tostring(all)
  end
  for _, w in ipairs(all) do
    local got, id = pcall(function() return w:id() end)
    if got and id then index[id] = { win = w, via = "allWindows" } end
  end
  local ok, windows = pcall(function() return hs.window.filter.default:getWindows() end)
  if ok then
    for _, w in ipairs(windows) do
      local got, id = pcall(function() return w:id() end)
      if got and id and not index[id] then index[id] = { win = w, via = "filter.default" } end
    end
  end
  local note = "ran"
  if not ok then note = "failed: " .. tostring(windows) end
  return index, note, nil
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
-- "is not there" need different answers.
function M.observe()
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

  local index, filter_note, list_err = nameable()
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

  -- Read as the windows are: a just-launched app can be listed before it can
  -- be read, so one that raises is skipped, and a list that cannot be had at
  -- all is recorded, never left looking like nothing running.
  -- An app that cannot be read is retried with the whole list; one that
  -- still cannot be is counted, never quietly taken for not running.
  local got, read = attempts(4, function()
    local bundles = {}
    for _, app in ipairs(hs.application.runningApplications()) do
      local b = app:bundleID()
      if b then bundles[#bundles + 1] = b end
    end
    return bundles
  end)
  if got then
    world.apps_running = read
  else
    world.apps_running_error = "the running apps could not be read four times: " .. tostring(read)
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
  local app = hs.application.get(bundle)
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
    hs.timer.usleep(250000)
    waited = waited + 0.25
  end
  return { status = "failed", reason = string.format("launched, but no standard window within %d s", M.LAUNCH_TIMEOUT) }
end

local show_desktop -- below, with the hand

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
  if el:pid() ~= pid then return "another app" end
  local win_el = role == "AXWindow" and el or el:attributeValue("AXWindow")
  local hw = win_el and win_el:asHSWindow()
  if not (hw and hw:id() == id) then return "another window" end
  if GRAB_ROLES[role] then return "grab" end
  return "a control (" .. tostring(role) .. ")"
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
  local app = win:application()
  local pid = app and app:pid()
  local frame, zoom = rect(win:frame()), rect(win:zoomButtonRect())
  local tried = {}
  for _, p in ipairs(P.grab_candidates(frame, zoom)) do
    local verdict = hit_test(p, id, pid)
    if verdict == "grab" then return { point = p, frame = frame } end
    tried[#tried + 1] = string.format("(%d,%d) %s", p.x, p.y, verdict)
  end
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
function LEG.carry(ctx, leg, id)
  local g, why = grab_point(id)
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
      return string.format("held and pressed Move-space %s, and after %d s the window is on %s and screen %s shows %s,"
        .. " not space %s", leg.side, STEP_WAIT,
        spaces and ("{" .. table.concat(list(spaces), ",") .. "}") or ("what could not be read: " .. tostring(serr)),
        tostring(leg.screen), at and ("space " .. tostring(at)) or ("what could not be read: " .. tostring(aerr)),
        tostring(step))
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
  local g, why = grab_point(id)
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
local function shown_space(id)
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

-- Observe until done(world) holds, for up to `seconds` on the monotonic
-- clock, a quarter of a second between reads. An observe that raises while a
-- window is half there is tried again. Returns the last world read (done or
-- not), or raises the last error when no observe succeeded. The one polling
-- loop the settles below share.
local function observe_until(done, seconds)
  local deadline = now() + seconds * 1e9
  local world, err
  while true do
    local ok, got = pcall(M.observe)
    if ok then
      world = got
      if done(world) then return world end
    else
      err = got
    end
    if now() >= deadline then break end
    hs.timer.usleep(250000)
  end
  if world then return world end
  error(err, 0)
end

-- After create_space: until com.apple.spaces has caught up with the live
-- list, for up to 3 s (design.md, apply 7).
local function observe_settled()
  return observe_until(function(world)
    for _, s in ipairs(world.screens or {}) do
      if s.order_error then return false end
    end
    return true
  end, 3)
end

-- After launches: until every app whose launch was done runs and has a
-- window plan could claim named on a desktop, for up to the launch timeout.
-- A launched window becomes nameable a beat after the launch sees it (vc's
-- hand runs, 16 Oct 2026). Plan reports what is still not named as unseen.
local function observe_launched(launched)
  return observe_until(function(world) return #P.unsettled_launches(world, launched) == 0 end, M.LAUNCH_TIMEOUT)
end

-- A plan that finds an entry unseen is planned again from fresh observes for
-- up to this long: a window on a desktop its display is not showing is named
-- in one read and not the next (vc's hand run, 16 Oct 2026), so one read is
-- not taken as the answer.
local UNSEEN_SECONDS = 1.5

-- plan from WORLD, planned again from fresh observes while an entry is
-- unseen, up to UNSEEN_SECONDS. A retry that cannot observe keeps the plan
-- in hand. Returns the world planned from, its ops, and plan's refusal.
local function plan_settled(desk, world, options)
  local ops, err = P.plan(desk, world, options)
  if not (ops and #only(ops, { unseen = true }) > 0) then return world, ops, err end
  local ok, later = pcall(observe_until, function(w)
    local o, e = P.plan(desk, w, options)
    ops, err, world = o, e, w
    return not (o and #only(o, { unseen = true }) > 0)
  end, UNSEEN_SECONDS)
  if not ok then return world, ops, err end
  return later, ops, err
end

-- apply, steps 5 to 11 of design.md "apply, in order": everything after the
-- CLI's preconditions and validation. A refusal before anything changed is
-- refused, which the CLI reports as exit 2. Once the first op has run, every
-- failure is a result instead, so the report always says what was done.
function M.apply(desk, options)
  options = options or {}
  local world = M.observe()
  -- Only Hammerspoon can say whether it holds the grant; the preferences are
  -- the CLI's to judge, before it asks (D26).
  if world.accessibility ~= true then
    refuse("Hammerspoon has no Accessibility grant, so it can neither name a window nor move one: System Settings >"
      .. " Privacy & Security > Accessibility")
  end
  local ops, err
  world, ops, err = plan_settled(desk, world, { no_create = options.no_create, no_launch = options.no_launch,
    map = options.map })
  if not ops then refuse(err) end

  local ctx = { hand = new_hand(), unmoved = {}, world = world }
  ctx.keys, ctx.keys_error = move_keys()
  if P.needs_hand(ops, world) then
    if not ctx.keys then refuse(ctx.keys_error) end
    local free, why = hands_free()
    if not free then refuse(why) end
  end

  local results = {}
  -- One step after things began to change: its failure is a result, and the
  -- report says the entries after it were not finished.
  local function step(what, f, ...)
    local ok, a = pcall(f, ...)
    if ok then return a end
    results[#results + 1] = { op = what, status = "failed", reason = tostring(a) }
    return nil
  end

  local creates = only(ops, { create_space = true })
  local launches = only(ops, { launch = true })
  local changed = #creates > 0 or #launches > 0

  -- Steps 7 to 10, from the second plan to the last place. Once anything
  -- has changed it runs as one step, so nothing in it can escape as a
  -- refusal.
  local function the_rest()
    local rest = ops
    if changed then
      local running_before = P.running_set(ctx.world_before)
      local again, aerr
      ctx.world, again, aerr = plan_settled(desk, ctx.world, { no_create = true, after_create = #creates > 0,
        user_no_create = options.no_create,
        no_launch = options.no_launch, map = options.map,
        launched = ctx.launched, running_before = running_before })
      if not again then error("the plan after creating and launching refused: " .. tostring(aerr), 0) end
      rest = again
    end
    -- Everything but what ran already: a kind this does not know reaches
    -- execute, which fails it out loud, never dropped here unreported.
    rest = except(rest, { create_space = true, launch = true })
    if P.needs_hand(rest, ctx.world) then
      local took, why = take_hand(ctx)
      if not took then ctx.stopped = why end
    end
    append(results, M.execute(rest, ctx))
  end

  ctx.world_before = world
  ctx.launched = {}
  local going = true
  if #creates > 0 then
    append(results, step("execute", M.execute, creates, ctx) or {})
    ctx.world = step("observe", observe_settled)
    going = ctx.world ~= nil
  end
  if going and #launches > 0 then
    local done = step("execute", M.execute, launches, ctx) or {}
    append(results, done)
    for _, r in ipairs(done) do ctx.launched[P.app_key(r.bundle)] = r.status == "done" end
    ctx.world = step("observe", observe_launched, ctx.launched)
    going = ctx.world ~= nil
  end
  -- Run as a step even when nothing changed before it, because it moves
  -- windows itself: a failure inside it is a result, never a refusal.
  if going then step("plan", the_rest) end

  give_back(ctx, results)

  local final_ok, final = pcall(M.observe)
  if not final_ok then
    results[#results + 1] = { op = "final_observe", status = "failed", reason = tostring(final) }
    final = nil
  end
  local lines, code = P.apply_report(desk, results)
  return { ops = ops, results = results, report = lines, exit = code, world = final }
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
    local _, ops, err = plan_settled(desk, M.observe(), options)
    if not ops then refuse(err) end
    return { ops = ops, report = P.plan_report(ops) }
  end,
  apply = function(desk, options)
    if type(desk) ~= "table" then refuse("apply needs the desk") end
    return M.apply(desk, options)
  end,
}

-- Verbs that run longer than the hs client waits (4 s, D20 as amended):
-- scheduled on a timer, the IPC call returning at once, the response file the
-- only answer. THE SAME LIST AS SCHEDULED_VERBS in opt/arngz/arngz, which
-- arngz.bats holds the two to.
local SCHEDULED = { apply = true }

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
  if ok then
    out.status = "ok"
    out.verb = request.verb
    return out
  end
  if type(out) == "table" and out.refused then
    return { status = "error", kind = "refused", verb = request.verb, error = tostring(out.refused) }
  end
  return { status = "error", kind = "lua_error", verb = request.verb, error = tostring(out) }
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
  elseif not VERBS[request.verb] then
    return respond(response_path, { status = "error", kind = "refused", verb = request.verb,
      error = "the engine has no verb " .. tostring(request.verb) })
  end
  if not SCHEDULED[request.verb] then return respond(response_path, answer(request)) end

  -- One at a time: two applies would take the one pointer from each other.
  -- The state lives in globals because dofile makes this module anew at
  -- every call, and the timer is held there so it is not collected before
  -- it fires (dc, D20).
  local running = rawget(_G, "arngz_running")
  if running then
    return respond(response_path, { status = "error", kind = "refused", verb = request.verb,
      error = string.format("an %s is already running (asked for at %s); wait for it to finish", running.verb, running.at) })
  end
  rawset(_G, "arngz_running", { verb = request.verb, at = utc_now() })
  local scheduled, timer = pcall(hs.timer.doAfter, 0, function()
    local ok, line = pcall(function() return respond(response_path, answer(request)) end)
    if not ok then print("arngz: error: " .. tostring(line)) end
    rawset(_G, "arngz_running", nil)
    rawset(_G, "arngz_timer", nil)
  end)
  if not scheduled then
    -- Never left marked as running when nothing was scheduled.
    rawset(_G, "arngz_running", nil)
    return respond(response_path, { status = "error", kind = "refused", verb = request.verb,
      error = "could not schedule " .. request.verb .. ": " .. tostring(timer) })
  end
  rawset(_G, "arngz_timer", timer)
  return "arngz: scheduled " .. request.verb
end

return M
