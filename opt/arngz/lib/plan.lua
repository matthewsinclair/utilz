-- arngz's planner: plan(desk, world, options) -> ops (ST0026, design.md D7, D12).
--
-- **PURE, AND THE SUITE HOLDS IT TO THAT.** Nothing in this file calls
-- Hammerspoon: its inputs are two tables, a desk and a world as observe()
-- records it, and its output is a list of ops. That is what lets it be tested
-- under plain Lua on a Linux runner where Hammerspoon cannot exist. The bats
-- suite greps this file for the Hammerspoon namespace and fails on a hit, so
-- the comments here never spell it either.
--
-- Written in the intersection of Lua 5.1 and 5.4 (no goto, no integer
-- division, no math.tointeger, no table.unpack), because the runner has
-- lua5.4, this machine has LuaJIT, and Hammerspoon carries 5.4.
--
-- Frames come from the screen's frame and the desk's own grid (D7), never from
-- Hammerspoon's grid module, whose grid is global state this planner cannot
-- see or depend on.

local P = {}

-- A window whose frame is within this many points of its cell on every edge is
-- in place. Apps that size in character cells or enforce a minimum land a
-- point or two off, and planning a place for that every run would make apply
-- report a failure that is the app's rounding rather than arngz's.
P.FRAME_SLACK = 2

-- ------------------------------------------------------------- geometry

local function round(v)
  return math.floor(v + 0.5)
end

-- "x,y wxh" -> {x, y, w, h} in cells, or nil for "fullscreen" and anything
-- else. The validator has already refused a malformed layout.
function P.parse_layout(layout)
  local x, y, w, h = string.match(layout or "", "^(%d+),(%d+) (%d+)x(%d+)$")
  if not x then return nil end
  return { x = tonumber(x), y = tonumber(y), w = tonumber(w), h = tonumber(h) }
end

function P.parse_grid(grid)
  local w, h = string.match(grid or "", "^(%d+)x(%d+)$")
  if not w then return nil end
  return { w = tonumber(w), h = tonumber(h) }
end

-- The frame a layout means on a screen, in points, from the screen's frame
-- (which excludes the menu bar and the Dock) and the desk's grid.
function P.cell_frame(screen_frame, grid, cell)
  local cw, ch = screen_frame.w / grid.w, screen_frame.h / grid.h
  local x0 = screen_frame.x + cell.x * cw
  local y0 = screen_frame.y + cell.y * ch
  local x1 = screen_frame.x + (cell.x + cell.w) * cw
  local y1 = screen_frame.y + (cell.y + cell.h) * ch
  return { x = round(x0), y = round(y0), w = round(x1) - round(x0), h = round(y1) - round(y0) }
end

function P.frames_agree(a, b, slack)
  slack = slack or P.FRAME_SLACK
  if not a or not b then return false end
  return math.abs(a.x - b.x) <= slack and math.abs(a.y - b.y) <= slack
    and math.abs(a.w - b.w) <= slack and math.abs(a.h - b.h) <= slack
end

-- Where a screen sits relative to the primary one (D6 as amended by hv,
-- 16 Oct 2026). COMPOUND, because a one-word direction ties: hv's two
-- identical panels both sit above the laptop, and "above" could not tell them
-- apart. The screen's centre is placed against the primary's extent on each
-- axis -- left of it, across it or right of it; above, level with or below it
-- -- and the across and level parts are left out of the name: `above-left`,
-- `above`, `right`, `below-right`, and `main` for the primary itself.
-- observe() records it, discovery writes it, display matching compares it.
function P.position(frame, primary_frame)
  if frame.x == primary_frame.x and frame.y == primary_frame.y
    and frame.w == primary_frame.w and frame.h == primary_frame.h then
    return "main"
  end
  local cx, cy = frame.x + frame.w / 2, frame.y + frame.h / 2
  local horizontal, vertical = "", ""
  if cx < primary_frame.x then
    horizontal = "left"
  elseif cx > primary_frame.x + primary_frame.w then
    horizontal = "right"
  end
  if cy < primary_frame.y then
    vertical = "above"
  elseif cy > primary_frame.y + primary_frame.h then
    vertical = "below"
  end
  if vertical ~= "" and horizontal ~= "" then return vertical .. "-" .. horizontal end
  if vertical ~= "" then return vertical end
  if horizontal ~= "" then return horizontal end
  -- A screen centred within the primary's extent on both axes overlaps it
  -- (mirroring, or a picture-in-picture layout): named, not guessed.
  return "overlapping"
end

-- ------------------------------------------------------------- matching

-- A desk's `size` is the panel's, so it is read from the full frame, which
-- includes the menu bar and the Dock that `frame` leaves out.
local function size_of(screen)
  local f = screen.full_frame or screen.frame
  return string.format("%dx%d", round(f.w), round(f.h))
end

local function candidates_text(list)
  local names = {}
  for _, s in ipairs(list) do
    names[#names + 1] = string.format("%s (%s, %s, %s)", s.uuid, tostring(s.name), size_of(s), tostring(s.position))
  end
  if #names == 0 then return "none" end
  return table.concat(names, "; ")
end

-- Each desk display to one screen (design.md, "Display matching", D6): the
-- same UUID; else the one screen with the same name and size; else, among
-- several, the one in the same position; --map overrides one display by name.
-- Returns screens indexed like desk.displays, or nil and a refusal naming the
-- display and every candidate.
function P.match_displays(desk, world, options)
  local map = (options and options.map) or {}
  local names = {}
  for _, d in ipairs(desk.displays or {}) do
    if d.name then names[d.name] = true end
  end
  for key in pairs(map) do
    if not names[key] then
      local known = {}
      for n in pairs(names) do known[#known + 1] = n end
      table.sort(known)
      return nil, string.format("--map %s: the desk has no display named %s; its displays: %s",
        key, key, (#known > 0) and table.concat(known, ", ") or "none named")
    end
  end
  local by_uuid = {}
  for _, s in ipairs(world.screens or {}) do by_uuid[s.uuid] = s end

  local matched, taken = {}, {}
  for i, d in ipairs(desk.displays or {}) do
    local m = d.match or {}
    local hit
    local mapped = d.name and map[d.name]
    if mapped then
      hit = by_uuid[mapped]
      if not hit then
        return nil, string.format("--map %s=%s names no screen; screens: %s",
          d.name, mapped, candidates_text(world.screens or {}))
      end
    elseif m.uuid and by_uuid[m.uuid] then
      hit = by_uuid[m.uuid]
    else
      local same = {}
      for _, s in ipairs(world.screens or {}) do
        if m.name and s.name == m.name and (not m.size or size_of(s) == m.size) then
          same[#same + 1] = s
        end
      end
      if #same == 1 then
        hit = same[1]
      elseif #same > 1 and m.position then
        local placed = {}
        for _, s in ipairs(same) do
          if s.position == m.position then placed[#placed + 1] = s end
        end
        if #placed == 1 then hit = placed[1] end
        same = (#placed > 1) and placed or same
      end
      if not hit then
        return nil, string.format("displays[%d] (%s) matches %s: %s",
          i - 1, tostring(d.name), (#same == 0) and "no screen" or "more than one screen",
          candidates_text((#same == 0) and (world.screens or {}) or same))
      end
    end
    if taken[hit.uuid] then
      return nil, string.format("displays[%d] (%s) and displays[%d] (%s) both match screen %s",
        taken[hit.uuid].index - 1, tostring(taken[hit.uuid].name), i - 1, tostring(d.name), hit.uuid)
    end
    taken[hit.uuid] = { index = i, name = d.name }
    matched[i] = hit
  end
  return matched
end

-- ------------------------------------------------------------- planning

-- The user (desktop) spaces of a screen, in Mission Control order. A desk's
-- space ordinal counts these alone: a full-screen window is a space of its own
-- that arngz leaves alone (D11), so it takes no ordinal.
function P.is_user_space(space_type)
  return space_type == "user"
end

function P.user_spaces(screen)
  local out = {}
  for _, sp in ipairs(screen.spaces or {}) do
    if P.is_user_space(sp.type) then out[#out + 1] = sp end
  end
  return out
end

-- A space whose type could not be read cannot be counted, and counting it as
-- "not a desktop" would plan a create_space for one that exists and shift
-- every ordinal after it. Refuse instead.
local function untyped_space(screen)
  for _, sp in ipairs(screen.spaces or {}) do
    if sp.type == nil then
      return string.format("space %s on screen %s has no type%s", tostring(sp.id), tostring(screen.uuid),
        sp.type_error and (": " .. tostring(sp.type_error)) or "")
    end
  end
  return nil
end

-- Every window observe() could name on a desktop space, with where it is. A
-- window on a full-screen space is left alone (D11), so it never enters the
-- pool a desk entry can claim from.
local function all_windows(world)
  local out = {}
  for _, s in ipairs(world.screens or {}) do
    for _, sp in ipairs(P.user_spaces(s)) do
      for _, w in ipairs(sp.windows or {}) do
        if w.named and w.standard and not w.minimized then
          out[#out + 1] = { win = w, screen = s, space = sp }
        end
      end
    end
  end
  return out
end

local function running_set(world)
  local set = {}
  for _, b in ipairs(world.apps_running or {}) do set[string.lower(b)] = true end
  return set
end

local function binding_of(world, bundle)
  for _, b in ipairs(world.app_bindings or {}) do
    if string.lower(b.bundle or "") == string.lower(bundle) then return b.target end
  end
  return nil
end

local function path_of(di, si, ai)
  return string.format("displays[%d].spaces[%d].apps[%d]", di - 1, si - 1, ai - 1)
end

-- Every entry's window pattern, tried against an empty title and against its
-- own text, so a malformed Lua pattern is refused with its desk path rather
-- than raised from string.find in the middle of planning. Both subjects,
-- because a matcher reports a malformed pattern only when matching reaches
-- the fault: "" stops at the first character, and the pattern's own text
-- carries the match through its literal prefix to "Utilz (" or "100%".
local function bad_pattern(desk)
  for di, d in ipairs(desk.displays or {}) do
    for si, sp in ipairs(d.spaces or {}) do
      for ai, a in ipairs(sp.apps or {}) do
        if a.window then
          local ok, err = pcall(string.find, "", a.window)
          if ok then ok, err = pcall(string.find, a.window, a.window) end
          if not ok then
            return path_of(di, si, ai) .. ".window is not a valid Lua pattern: " .. tostring(err)
          end
        end
      end
    end
  end
  return nil
end

-- The desk's app entries in the order windows are given to them: entries with
-- a window pattern first, so a bare entry for the same app takes only what no
-- pattern claimed (D5).
local function entries(desk)
  local patterned, bare = {}, {}
  for di, d in ipairs(desk.displays or {}) do
    for si, sp in ipairs(d.spaces or {}) do
      for ai, a in ipairs(sp.apps or {}) do
        local e = { display = di, space = si, app = a, path = path_of(di, si, ai) }
        if a.window then patterned[#patterned + 1] = e else bare[#bare + 1] = e end
      end
    end
  end
  for _, e in ipairs(bare) do patterned[#patterned + 1] = e end
  return patterned
end

-- plan(desk, world, options) -> ops, or nil and a refusal.
--
-- options: no_create, no_launch, bind (booleans) and map ({name = uuid}).
-- Each op carries `op`, its arguments, `reason`, and `path`, the desk path
-- that asked for it. Order is the order apply executes in: create_space, then
-- launch, then for each window move before place (D14), then bind and one
-- restart_dock.
function P.plan(desk, world, options)
  options = options or {}
  local grid = P.parse_grid(desk.grid)
  if not grid then return nil, "the desk's grid is not WxH: " .. tostring(desk.grid) end
  local pattern_refusal = bad_pattern(desk)
  if pattern_refusal then return nil, pattern_refusal end
  local screens, refusal = P.match_displays(desk, world, options)
  if not screens then return nil, refusal end
  for _, s in ipairs(screens) do
    local why = untyped_space(s)
    if why then return nil, why end
  end

  local creates, launches, windows, binds = {}, {}, {}, {}

  for di, d in ipairs(desk.displays or {}) do
    local s = screens[di]
    local have, need = #P.user_spaces(s), #(d.spaces or {})
    if need > have and not options.no_create then
      for n = have + 1, need do
        creates[#creates + 1] = {
          op = "create_space", screen = s.uuid,
          path = string.format("displays[%d].spaces[%d]", di - 1, n - 1),
          reason = string.format("display %s needs %d spaces and has %d", tostring(d.name), need, have),
        }
      end
    end
  end

  local running = running_set(world)
  local launched, claimed = {}, {}
  local pool = all_windows(world)
  for _, e in ipairs(entries(desk)) do
    local a, s = e.app, screens[e.display]
    local bundle = a.app
    if not running[string.lower(bundle)] then
      if not options.no_launch and not launched[bundle] then
        launched[bundle] = true
        launches[#launches + 1] = {
          op = "launch", bundle = bundle, path = e.path,
          reason = bundle .. " is not running",
        }
      end
    elseif a.layout ~= "fullscreen" then
      local cell = P.parse_layout(a.layout)
      if not cell then return nil, e.path .. ".layout is not x,y wxh: " .. tostring(a.layout) end
      local frame = P.cell_frame(s.frame, grid, cell)
      local target = P.user_spaces(s)[e.space]
      local took = 0
      for _, cand in ipairs(pool) do
        local w = cand.win
        local fits = not claimed[w.id] and string.lower(w.bundle or "") == string.lower(bundle)
        if fits and a.window then
          -- The match itself is protected: a malformed pattern can pass
          -- bad_pattern's probes and still fail on a real title.
          local ok, hit = pcall(string.find, w.title or "", a.window)
          if not ok then
            return nil, string.format("%s.window is not a valid Lua pattern on window title %q: %s",
              e.path, w.title or "", tostring(hit))
          end
          fits = hit ~= nil
        end
        if fits then
          claimed[w.id] = true
          took = took + 1
          local moving = (target == nil) or (cand.space.id ~= target.id)
          if moving then
            windows[#windows + 1] = {
              op = "move", window = w.id, screen = s.uuid, ordinal = e.space, path = e.path,
              reason = string.format("%s %q is on %s space %d, not space %d of display %s",
                bundle, w.title or "", cand.screen.name or cand.screen.uuid, cand.space.ordinal or 0,
                e.space, tostring(desk.displays[e.display].name)),
            }
          end
          if moving or not P.frames_agree(w.frame, frame) then
            windows[#windows + 1] = {
              op = "place", window = w.id, frame = frame, path = e.path,
              reason = string.format("%s %q to %s on display %s", bundle, w.title or "", a.layout,
                tostring(desk.displays[e.display].name)),
            }
          end
        end
      end
      -- Running, but no window took this entry: said, never left looking like
      -- an entry already in place. execute performs nothing for it; the report
      -- names it as unseen (design.md, apply step 11).
      if took == 0 then
        windows[#windows + 1] = {
          op = "unseen", bundle = bundle, path = e.path,
          reason = string.format("%s is running and no standard window of it on a desktop space%s could be named"
            .. " (a full-screen window is left alone, and one Accessibility cannot name is not seen)", bundle,
            a.window and (" matching " .. string.format("%q", a.window)) or ""),
        }
      end
    end
    if options.bind then
      local target = P.user_spaces(s)[e.space]
      if not (target and target.uuid) then
        -- Asked for and not plannable: kept as a bind with no space, and the
        -- reason, rather than dropped.
        binds[#binds + 1] = {
          op = "bind", bundle = bundle, path = e.path,
          reason = (target == nil) and "its space does not exist yet, so there is no space to bind it to"
            or "its space's uuid could not be read, so it cannot be named in a binding",
        }
      elseif binding_of(world, bundle) ~= target.uuid then
        binds[#binds + 1] = {
          op = "bind", bundle = bundle, space = target.uuid, path = e.path,
          reason = string.format("%s is bound to %s, not this space", bundle, tostring(binding_of(world, bundle))),
        }
      end
    end
  end

  local ops, restartable = {}, 0
  for _, list in ipairs({ creates, launches, windows, binds }) do
    for _, op in ipairs(list) do ops[#ops + 1] = op end
  end
  for _, b in ipairs(binds) do
    if b.space then restartable = restartable + 1 end
  end
  -- Only a bind that names a space can take effect, so only that is worth a
  -- Dock restart.
  if restartable > 0 then
    ops[#ops + 1] = { op = "restart_dock", reason = "the Dock reads app bindings only when it starts" }
  end
  return ops
end

-- ------------------------------------------------------------- the report

-- The lines the CLI prints for an observe. Pure, and here rather than in the
-- engine module, so it counts desktops with the planner's one predicate and is
-- tested where the planner is.
function P.observe_report(world)
  local lines = {}
  for _, s in ipairs(world.screens or {}) do
    local windows, named = 0, 0
    for _, sp in ipairs(s.spaces or {}) do
      windows = windows + (sp.window_ids or 0)
      named = named + (sp.named or 0)
    end
    lines[#lines + 1] = string.format("%s %s (%s): %d spaces, %d desktop; %d windows, %d named",
      tostring(s.position), tostring(s.name), tostring(s.uuid), #(s.spaces or {}), #P.user_spaces(s), windows, named)
  end
  lines[#lines + 1] = string.format("separate spaces %s, accessibility %s, stage manager %s, %d Dock bindings",
    tostring(world.separate_spaces), tostring(world.accessibility), tostring(world.stage_manager),
    #(world.app_bindings or {}))
  return lines
end

return P
