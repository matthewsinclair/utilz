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
-- performs ops and reads back after each one.
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

-- How long launch waits for an app's first window (design.md, apply step 7).
M.LAUNCH_TIMEOUT = 20

-- ---------------------------------------------------------------- helpers

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
local function nameable()
  local index = {}
  for _, w in ipairs(hs.window.allWindows()) do
    index[w:id()] = { win = w, via = "allWindows" }
  end
  local ok, windows = pcall(function() return hs.window.filter.default:getWindows() end)
  if ok then
    for _, w in ipairs(windows) do
      local id = w:id()
      if id and not index[id] then index[id] = { win = w, via = "filter.default" } end
    end
  end
  local note = "ran"
  if not ok then note = "failed: " .. tostring(windows) end
  return index, note
end

local function describe(id, index)
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

-- Stage Manager is a Window Manager setting; arngz refuses to run under it.
local function stage_manager(prefs)
  if not prefs then return nil end
  local v = prefs.GloballyEnabled
  if v == nil then return false end
  return v == true or v == 1
end

-- ---------------------------------------------------------------- observe

-- The world as it is now. Read-only. Every lookup that can fail records its
-- error beside the value rather than dropping it, because "could not see" and
-- "is not there" need different answers.
function M.observe()
  local data, derr = hs.spaces.data_managedDisplaySpaces()
  local uuids = {}
  for _, display in ipairs(data or {}) do
    for _, space in ipairs(display.Spaces or {}) do
      uuids[space.ManagedSpaceID] = space.uuid
    end
  end

  local index, filter_note = nameable()
  local primary = hs.screen.primaryScreen()
  local primary_frame = rect(primary:fullFrame())
  local world = {
    taken_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    macos = hs.host.operatingSystemVersionString(),
    hammerspoon = hs.processInfo.version,
    accessibility = hs.accessibilityState(false),
    separate_spaces = hs.spaces.screensHaveSeparateSpaces(),
    window_filter = filter_note,
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
      active_error = aerr,
      spaces = {},
    }
    local spaces, serr = hs.spaces.spacesForScreen(uuid)
    entry.spaces_error = serr
    for ordinal, id in ipairs(spaces or {}) do
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
        windows_error = werr,
        windows = windows,
      }
    end
    world.screens[#world.screens + 1] = entry
  end

  for _, app in ipairs(hs.application.runningApplications()) do
    local b = app:bundleID()
    if b then world.apps_running[#world.apps_running + 1] = b end
  end

  local spaces_prefs, spaces_err = read_defaults("com.apple.spaces")
  local dock_prefs, dock_err = read_defaults("com.apple.dock")
  local wm_prefs, wm_err = read_defaults("com.apple.WindowManager")
  world.prefs_errors = { spaces = spaces_err, dock = dock_err, window_manager = wm_err }
  -- Read directly, never with `t and t[k] or nil`, which turns a stored false
  -- (mru-spaces is one) into an absent key (dc's spike). Absent means unset.
  if dock_prefs then world.mru_spaces = dock_prefs["mru-spaces"] end
  world.stage_manager = stage_manager(wm_prefs)
  if spaces_prefs and type(spaces_prefs["app-bindings"]) == "table" then
    for bundle, target in pairs(spaces_prefs["app-bindings"]) do
      world.app_bindings[#world.app_bindings + 1] = { bundle = bundle, target = target }
    end
  end
  return world
end

-- ---------------------------------------------------------------- execute

-- Ops whose route is not measured. WP-01's spike showed moveWindowToSpace
-- returning true and moving nothing, and a written Dock binding not taking, so
-- execute refuses to call either rather than report a lie as done. Their
-- route lands when WP-01 closes.
local UNROUTED = { move = true, bind = true, restart_dock = true }

-- Ops that ask for nothing to be done and carry what the report says.
local REPORT_ONLY = { unseen = "unseen" }

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

local function first_window(bundle)
  local app = hs.application.get(bundle)
  if not app then return nil end
  local w = app:allWindows()
  return w and w[1] or nil
end

local function exec_launch(op)
  local out, ok, _, rc = hs.execute("/usr/bin/open -b " .. shell_quote(op.bundle) .. " 2>&1")
  if not ok then
    local said = (out or ""):gsub("%s+$", "")
    -- What open prints for a bundle id nothing on this Mac carries, measured on
    -- macOS 27.0.1: only that is "not installed"; any other failure is a
    -- failure, never quietly a skip.
    if string.find(said, "determine the application with bundle identifier", 1, true) then
      return { status = "skipped", reason = "not installed: " .. said }
    end
    return { status = "failed", reason = string.format("open -b exited %s: %s", tostring(rc), said) }
  end
  local waited = 0
  while waited < M.LAUNCH_TIMEOUT do
    local w = first_window(op.bundle)
    if w then return { status = "done", readback = { window = w:id(), waited = waited } } end
    hs.timer.usleep(250000)
    waited = waited + 0.25
  end
  return { status = "failed", reason = string.format("launched, but no window within %d s", M.LAUNCH_TIMEOUT) }
end

local function exec_place(op)
  local w = hs.window.get(op.window)
  if not w then return { status = "failed", reason = "window " .. tostring(op.window) .. " is not visible to Accessibility" } end
  w:setFrame(op.frame, 0)
  hs.timer.usleep(150000)
  local got = rect(w:frame())
  if P.frames_agree(got, op.frame) then
    return { status = "done", readback = { frame = got } }
  end
  return { status = "failed", reason = "setFrame returned, and the window reads back elsewhere", readback = { frame = got } }
end

local EXEC = { create_space = exec_create_space, launch = exec_launch, place = exec_place }

-- Perform each op in order and read back after each one (D14). Nothing is
-- reported done that the readback does not show.
function M.execute(ops)
  local results = {}
  for i, op in ipairs(ops or {}) do
    local r
    if REPORT_ONLY[op.op] then
      r = { status = REPORT_ONLY[op.op], reason = op.reason }
    elseif UNROUTED[op.op] then
      r = { status = "failed", reason = "no route measured yet" .. (op.reason and ("; " .. op.reason) or "") }
    elseif EXEC[op.op] then
      local ok, res = pcall(EXEC[op.op], op)
      if ok then r = res else r = { status = "failed", reason = "lua error: " .. tostring(res) } end
    else
      r = { status = "failed", reason = "unknown op " .. tostring(op.op) }
    end
    r.op = op.op
    r.index = i
    r.path = op.path
    results[#results + 1] = r
  end
  return results
end

-- ---------------------------------------------------------------- the contract

-- The engine's verbs. Each answers with what the CLI renders -- for observe,
-- the world and the report lines P.observe_report computes -- so the CLI
-- renders and never recomputes (design.md, "The engine").
-- A refusal from a pure function travels back as an error raised here, which
-- run() turns into an error response the CLI names.
local VERBS = {
  observe = function()
    local world = M.observe()
    return { world = world, report = P.observe_report(world) }
  end,
  -- discover: the world as a desk (WP-04). options.grid, options.name.
  discover = function(_, options)
    local world = M.observe()
    local desk, notes = P.desk_from_world(world, { grid = options.grid, name = options.name })
    if not desk then error(notes, 0) end
    return { desk = desk, report = notes }
  end,
  -- plan: what apply would do, and nothing done (diff, and apply --dry-run).
  -- execute is never called on this path.
  plan = function(desk, options)
    if type(desk) ~= "table" then error("plan needs the desk", 0) end
    local world = M.observe()
    local ops, err = P.plan(desk, world, options)
    if not ops then error(err, 0) end
    return { ops = ops, report = P.plan_report(ops) }
  end,
}

-- The IPC entry. Reads {verb, desk, options} from request_path, writes the
-- response to response.json beside it, and returns one status line. A failure
-- inside run is a response too; a failure loading this module surfaces through
-- hs's exit code and output, which the CLI names.
function M.run(request_path)
  if type(request_path) ~= "string" or request_path == "" then
    return "arngz: error: run needs the request file's path, and was given " .. tostring(request_path)
  end
  local response_path = (dirname(request_path) or ".") .. "/response.json"
  local read_ok, request = pcall(hs.json.read, request_path)
  local response
  if not read_ok then
    response = { status = "error", error = "cannot read the request at " .. tostring(request_path) .. ": " .. tostring(request) }
  elseif type(request) ~= "table" then
    response = { status = "error", error = "cannot read the request at " .. tostring(request_path)
      .. ": hs.json.read returned nothing, so it is missing or not JSON" }
  elseif not VERBS[request.verb] then
    response = { status = "error", verb = request.verb, error = "the engine has no verb " .. tostring(request.verb) }
  else
    local ok, out = pcall(VERBS[request.verb], request.desk, request.options or {})
    if ok then
      response = out
      response.status = "ok"
      response.verb = request.verb
    else
      response = { status = "error", verb = request.verb, error = tostring(out) }
    end
  end
  -- WRITTEN ASIDE AND RENAMED, so the response appears whole or not at all.
  -- The CLI treats the file's appearance as the answer, and does not wait for
  -- hs to return: measured 16 Oct 2026, hs -c sometimes never returns after
  -- run() has finished and written its response, -t notwithstanding.
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

return M
