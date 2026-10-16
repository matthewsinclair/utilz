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
P.round = round

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

-- A screen's name without the " (n)" Hammerspoon appends when two panels share
-- a name. The suffix follows enumeration order, so it is not identity: it is
-- stripped on both sides of a match (D6 as amended, 16 Oct 2026), and discover
-- never writes it.
function P.panel_name(name)
  if type(name) ~= "string" then return name end
  return (string.gsub(name, "%s%(%d+%)$", ""))
end

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
        if m.name and P.panel_name(s.name) == P.panel_name(m.name) and (not m.size or size_of(s) == m.size) then
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

-- What observe could not read, refused rather than planned as empty: the
-- windows that could not be listed at all, a screen whose spaces, or their
-- order (D22), could not be read, a space whose type could not be read, or a
-- space whose windows could not be read. Counting an unread space as "not a
-- desktop", or its windows as none, would plan a create_space for a space
-- that exists, shift every ordinal after it, and miss windows that are there.
-- Over every screen, because the window pool is the whole world's. Plan and
-- discover both refuse through this one check. One window that went away
-- between being listed and being read is not this: it is unnamed, with its
-- read_error, and not seen.
local function unread(world)
  if world.windows_list_error then
    return "the windows could not be listed: " .. tostring(world.windows_list_error)
  end
  if world.apps_running_error then
    return "the running apps could not be listed: " .. tostring(world.apps_running_error)
  end
  for _, s in ipairs(world.screens or {}) do
    if s.spaces_error then
      return string.format("the spaces of screen %s could not be read: %s", tostring(s.uuid), tostring(s.spaces_error))
    end
    if s.order_error then
      return string.format("the order of screen %s's spaces could not be read: %s", tostring(s.uuid), tostring(s.order_error))
    end
    for _, sp in ipairs(s.spaces or {}) do
      if sp.type == nil then
        return string.format("space %s on screen %s has no type%s", tostring(sp.id), tostring(s.uuid),
          sp.type_error and (": " .. tostring(sp.type_error)) or "")
      end
      if sp.windows_error then
        return string.format("the windows of space %s on screen %s could not be read: %s", tostring(sp.id),
          tostring(s.uuid), tostring(sp.windows_error))
      end
    end
  end
  return nil
end

-- A window a desk entry can claim: named, standard and not minimized. Plan's
-- pool and discover's pattern counts both read this, so a discovered desk
-- plans clean against the world it came from.
local function claimable(w)
  return w.named and w.standard and not w.minimized
end
P.claimable = claimable

-- Every space each window is listed on, and whether one of them is being
-- shown: { [id] = { spaces = {[space id] = true}, count, shown } }. The one
-- reading of a window on several spaces that plan, discover and needs_hand
-- share.
function P.listings(world)
  local out = {}
  for _, s in ipairs(world.screens or {}) do
    for _, sp in ipairs(s.spaces or {}) do
      for _, w in ipairs(sp.windows or {}) do
        local l = out[w.id] or { spaces = {}, count = 0, shown = false }
        if not l.spaces[sp.id] then
          l.spaces[sp.id] = true
          l.count = l.count + 1
        end
        if sp.active then l.shown = true end
        out[w.id] = l
      end
    end
  end
  return out
end

-- Every window observe() could name on a desktop space, with where it is. A
-- window on a full-screen space is left alone (D11), so it never enters the
-- pool a desk entry can claim from.
local function all_windows(world)
  local out = {}
  for _, s in ipairs(world.screens or {}) do
    for _, sp in ipairs(P.user_spaces(s)) do
      for _, w in ipairs(sp.windows or {}) do
        if claimable(w) then
          out[#out + 1] = { win = w, screen = s, space = sp }
        end
      end
    end
  end
  return out
end

-- An app's identity: its bundle id without regard to case, as macOS treats
-- it. Plan's claims, launches and running lookups, apply's launched set, and discover's
-- counts and NOT_RECORDED all key on this, so one app is never two.
local function app_key(bundle)
  return string.lower(bundle or "")
end
P.app_key = app_key

local function running_set(world)
  local set = {}
  for _, b in ipairs(world.apps_running or {}) do set[app_key(b)] = true end
  return set
end
P.running_set = running_set

-- Why the Dock bindings could not be read, or nil. An empty list beside this
-- is "could not see", never "none".
local function bindings_unread(world)
  local why = (world.prefs_errors or {}).spaces or world.bindings_error
  if why then return "the Dock bindings could not be read: " .. tostring(why) end
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
-- options: no_create and no_launch (booleans), after_create (a second plan,
-- so a space that does not exist is one whose creation failed),
-- user_no_create (a second plan: false when the person did not pass
-- --no-create, so a missing space is one that went away meanwhile), map
-- ({name = uuid}), and
-- launched ({app key = true when its launch was done, false when not}): the
-- apps apply has already launched, which a second plan never launches again
-- (design.md, apply 9). One whose launch was not done is the launch result's
-- to report; one whose launch was done and is not running now is reported
-- here, as gone. running_before ({app key = true}), given to a second plan,
-- launches nothing, and reports an app that was running then and is not now
-- as gone.
-- Each op carries `op`, its arguments, `reason`, and `path`, the desk path
-- that asked for it. Order is the order apply executes in: create_space, then
-- launch, then for each window move before place (D14). There is no --bind
-- in v1 (D10, AC-05.6).
function P.plan(desk, world, options)
  options = options or {}
  local grid = P.parse_grid(desk.grid)
  if not grid then return nil, "the desk's grid is not WxH: " .. tostring(desk.grid) end
  local pattern_refusal = bad_pattern(desk)
  if pattern_refusal then return nil, pattern_refusal end
  local unread_refusal = unread(world)
  if unread_refusal then return nil, unread_refusal end
  local screens, refusal = P.match_displays(desk, world, options)
  if not screens then return nil, refusal end

  local creates, launches, windows = {}, {}, {}
  local already = options.launched or {}

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
  -- Windows that went away, or were not backed yet, between being listed and
  -- being read: said in every unseen reason, because one may be the entry's.
  local unreadable, first_error = 0, nil
  for _, s in ipairs(world.screens or {}) do
    for _, sp in ipairs(s.spaces or {}) do
      for _, w in ipairs(sp.windows or {}) do
        if w.read_error then
          unreadable = unreadable + 1
          first_error = first_error or w.read_error
        end
      end
    end
  end
  local unread_note = (unreadable > 0)
    and string.format("; %d window(s) could not be read just now (%s)", unreadable, tostring(first_error)) or ""
  if (world.window_id_errors or 0) > 0 then
    unread_note = unread_note .. string.format("; %d window id read(s) failed (%s)",
      world.window_id_errors, tostring(world.window_id_error))
  end
  if world.window_filter and world.window_filter ~= "ran" then
    unread_note = unread_note .. "; the window filter that names windows on other spaces " .. world.window_filter
  end
  local listed = P.listings(world)
  for _, e in ipairs(entries(desk)) do
    local a, s = e.app, screens[e.display]
    local bundle = a.app
    if not running[app_key(bundle)] then
      if already[app_key(bundle)] ~= nil then
        -- Launched by this apply, and not running now: when its launch failed
        -- or was skipped, that result is the report's line; when it showed a
        -- window and has quit since, this says so, never "placed".
        if already[app_key(bundle)] == true then
          windows[#windows + 1] = {
            op = "gone", bundle = bundle, path = e.path,
            reason = bundle .. " was launched by this apply and is not running now",
          }
        end
        launched[app_key(bundle)] = true
      elseif options.running_before then
        -- A second plan launches nothing. An app running when apply began
        -- and not now quit in between: said, never launched mid-run. One
        -- that was not running then had its launch tried, or the run
        -- stopped before it, and that result is the report's.
        if options.running_before[app_key(bundle)] then
          windows[#windows + 1] = {
            op = "gone", bundle = bundle, path = e.path,
            reason = bundle .. " was running when apply began and is not now; apply does not launch it mid-run",
          }
        end
      elseif options.no_launch then
        windows[#windows + 1] = {
          op = "not_launched", bundle = bundle, path = e.path,
          reason = bundle .. " is not running, and --no-launch leaves it so",
        }
      elseif not launched[app_key(bundle)] then
        launched[app_key(bundle)] = true
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
        local fits = not claimed[w.id] and app_key(w.bundle) == app_key(bundle)
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
          -- A window on several spaces is in place when one of them is the
          -- target, whichever listing claimed it.
          local moving = (target == nil) or not listed[w.id].spaces[target.id]
          local several = listed[w.id].count > 1
          -- What happens to it: nothing, a move and a place, a place alone,
          -- or a report that says why neither can be done.
          local said
          if moving and target == nil and options.no_create then
            local why = "and --no-create leaves it so"
            if options.after_create then
              why = "and creating it failed (its create_space result says why)"
            elseif options.user_no_create == false then
              why = "and it has gone since apply began"
            end
            said = { op = "no_space", reason = string.format("space %d of display %s does not exist, %s", e.space,
              tostring(desk.displays[e.display].name), why) }
          elseif moving and target == nil and several then
            -- A window on every space is on the space about to be created
            -- too; the plan after creating it decides, and diff says so.
            said = { op = "pending", reason = string.format("%s %q is on every space, so it will be on space %d of"
              .. " display %s once that is created; the plan after creating it decides", bundle, w.title or "",
              e.space, tostring(desk.displays[e.display].name)) }
          elseif moving and several then
            -- On every space but the target's: no gesture carries it, so it
            -- is said here rather than failed at execute.
            said = { op = "unmovable", reason = string.format("%s %q is on %d spaces and not on space %d of display %s;"
              .. " arngz does not move a window on every space", bundle, w.title or "", listed[w.id].count, e.space,
              tostring(desk.displays[e.display].name)) }
          end
          if said then
            said.window, said.bundle, said.path = w.id, bundle, e.path
            windows[#windows + 1] = said
          else
            if moving then
              -- The target space's id when it exists; a space still to be
              -- created has none, and the plan after creating it has one.
              windows[#windows + 1] = {
                op = "move", window = w.id, screen = s.uuid, ordinal = e.space, path = e.path, bundle = bundle,
                space = target and target.id or nil, from_screen = cand.screen.uuid, from_space = cand.space.id,
                reason = string.format("%s %q is on %s space %d, not space %d of display %s",
                  bundle, w.title or "", cand.screen.name or cand.screen.uuid, cand.space.ordinal or 0,
                  e.space, tostring(desk.displays[e.display].name)),
              }
            end
            if moving or not P.frames_agree(w.frame, frame) then
              windows[#windows + 1] = {
                op = "place", window = w.id, frame = frame, path = e.path, bundle = bundle,
                reason = string.format("%s %q to %s on display %s", bundle, w.title or "", a.layout,
                  tostring(desk.displays[e.display].name)),
              }
            end
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
            .. " (a full-screen window is left alone, and one Accessibility cannot name is not seen)%s", bundle,
            a.window and (" matching " .. string.format("%q", a.window)) or "", unread_note),
        }
      end
    end
  end

  local ops = {}
  for _, list in ipairs({ creates, launches, windows }) do
    for _, op in ipairs(list) do ops[#ops + 1] = op end
  end
  return ops
end

-- The apps of `launched` ({app key = true when its launch was done}) that
-- are not running yet, or have no window plan could claim named on any space
-- yet: what apply waits on after launching, before it plans again. A
-- launched app can be listed in neither for a moment after its launch saw
-- its window (vc's hand runs, 16 Oct 2026).
function P.unsettled_launches(world, launched)
  local running = running_set(world)
  -- Plan's own pool, so "named" here means exactly what an entry can claim:
  -- a window on a full-screen space does not end the wait (D11).
  local named = {}
  for _, cand in ipairs(all_windows(world)) do
    if cand.win.bundle then named[app_key(cand.win.bundle)] = true end
  end
  local out = {}
  for key, done in pairs(launched or {}) do
    if done and not (named[key] and running[key]) then out[#out + 1] = key end
  end
  table.sort(out)
  return out
end

-- The desk's apps, each bundle id once, in desk order: what observe asks
-- about one by one, fresh, for whether it runs.
function P.desk_bundles(desk)
  local out, seen = {}, {}
  for _, d in ipairs(desk.displays or {}) do
    for _, sp in ipairs(d.spaces or {}) do
      for _, a in ipairs(sp.apps or {}) do
        local key = app_key(a.app)
        if not seen[key] then
          seen[key] = true
          out[#out + 1] = a.app
        end
      end
    end
  end
  return out
end

-- ------------------------------------------------------------- space order

-- A screen's spaces in Mission Control's order (D22): its list in
-- com.apple.spaces' SpacesDisplayConfiguration, found as the one list whose
-- spaces are exactly the screen's live spaces. The plist names the built-in
-- display "Main" and keeps lists for displays no longer attached, so a list
-- is never chosen by its name. `monitors` is the plist's Monitors array, each
-- { Spaces = { { ManagedSpaceID = id }, ... } }. Returns the ids in order, or
-- nil and why.
function P.order_spaces(live_ids, monitors)
  local live, n = {}, 0
  for _, id in ipairs(live_ids or {}) do
    live[id] = true
    n = n + 1
  end
  local found
  for _, m in ipairs(monitors or {}) do
    local ids, same = {}, true
    for _, sp in ipairs(m.Spaces or {}) do
      local id = sp.ManagedSpaceID
      ids[#ids + 1] = id
      if not live[id] then same = false end
    end
    if same and #ids == n and n > 0 then
      if found then
        return nil, "two lists in com.apple.spaces hold exactly this screen's spaces"
      end
      found = ids
    end
  end
  if not found then
    return nil, "no list in com.apple.spaces holds exactly this screen's spaces ("
      .. table.concat(live_ids or {}, ", ") .. "), so their order is not known"
  end
  return found
end

-- ------------------------------------------------------------- moving (D21)

-- Ported from dc's spike 2 (arngz-spike2.lua, ST0026 WP-01), which measured
-- the gestures these plan. Pure: the engine performs them.

-- A drag keeps this far from the ends of the edge two displays share.
P.MARGIN_PX = 40

local function clamp(v, lo, hi)
  if hi < lo then return (lo + hi) / 2 end
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

local function point(x, y) return { x = round(x), y = round(y) } end

-- Where two displays touch: the line they share and which way b lies from a,
-- or nil. Touching at a corner is not a shared edge. Frames are full frames
-- in Hammerspoon's coordinates, the primary's top left at 0,0, y down.
function P.touching(a, b)
  local function overlap(a1, a2, b1, b2)
    local lo, hi = math.max(a1, b1), math.min(a2, b2)
    if hi - lo > 2 then return lo, hi end
    return nil
  end
  local lo, hi
  if math.abs(a.x + a.w - b.x) <= 1 then
    lo, hi = overlap(a.y, a.y + a.h, b.y, b.y + b.h)
    if lo then return { axis = "x", at = b.x, lo = lo, hi = hi, dir = 1 } end
  end
  if math.abs(b.x + b.w - a.x) <= 1 then
    lo, hi = overlap(a.y, a.y + a.h, b.y, b.y + b.h)
    if lo then return { axis = "x", at = a.x, lo = lo, hi = hi, dir = -1 } end
  end
  if math.abs(a.y + a.h - b.y) <= 1 then
    lo, hi = overlap(a.x, a.x + a.w, b.x, b.x + b.w)
    if lo then return { axis = "y", at = b.y, lo = lo, hi = hi, dir = 1 } end
  end
  if math.abs(b.y + b.h - a.y) <= 1 then
    lo, hi = overlap(a.x, a.x + a.w, b.x, b.x + b.w)
    if lo then return { axis = "y", at = a.y, lo = lo, hi = hi, dir = -1 } end
  end
  return nil
end

-- The two points either side of a shared edge, 3 px in, as near to p along
-- the edge as the margin allows.
function P.crossing(edge, p)
  if edge.axis == "x" then
    local y = clamp(p.y, edge.lo + P.MARGIN_PX, edge.hi - P.MARGIN_PX)
    return point(edge.at - 3 * edge.dir, y), point(edge.at + 3 * edge.dir, y)
  end
  local x = clamp(p.x, edge.lo + P.MARGIN_PX, edge.hi - P.MARGIN_PX)
  return point(x, edge.at - 3 * edge.dir), point(x, edge.at + 3 * edge.dir)
end

-- The displays a drag passes through from one display to another, each
-- touching the next: breadth first, so the fewest crossings; nil when no
-- chain of shared edges joins them. Screens are { uuid, full }.
function P.route(screens, from, to)
  local by_uuid = {}
  for _, s in ipairs(screens or {}) do by_uuid[s.uuid] = s end
  if not (by_uuid[from] and by_uuid[to]) then return nil end
  local prev, seen, queue = {}, { [from] = true }, { from }
  while #queue > 0 do
    local u = table.remove(queue, 1)
    for _, s in ipairs(screens) do
      if not seen[s.uuid] and P.touching(by_uuid[u].full, s.full) then
        seen[s.uuid], prev[s.uuid] = true, u
        queue[#queue + 1] = s.uuid
      end
    end
  end
  if not seen[to] then return nil end
  local chain = { by_uuid[to] }
  while chain[1].uuid ~= from do table.insert(chain, 1, by_uuid[prev[chain[1].uuid]]) end
  return chain
end

-- A polyline from start to dest along a route, each segment inside one
-- display, so the pointer is never asked to cross a gap between displays.
function P.path(chain, start, dest)
  local points, p = {}, start
  for i = 1, #chain - 1 do
    local a, b = P.crossing(P.touching(chain[i].full, chain[i + 1].full), p)
    points[#points + 1] = a
    points[#points + 1] = b
    p = b
  end
  points[#points + 1] = dest
  return points
end

-- Where a dragged window is let go on the target display: its grab point
-- offset as the window's top left would land 80 points into the target's
-- visible frame, kept 10 points inside the target.
function P.drop_point(grab, window_frame, target)
  return point(
    clamp(target.frame.x + 80 + (grab.x - window_frame.x), target.full.x + 10, target.full.x + target.full.w - 10),
    clamp(target.frame.y + 80 + (grab.y - window_frame.y), target.full.y + 10, target.full.y + target.full.h - 10))
end

-- Points on the title bar's centre line, best first: just right of the zoom
-- button, then across the bar. The traffic lights sit on the bar's centre
-- line whatever the bar's height, so the zoom button gives the line.
function P.grab_candidates(frame, zoom)
  local y = zoom and (zoom.y + zoom.h / 2) or (frame.y + 12)
  local xs = {}
  if zoom then
    xs[#xs + 1] = zoom.x + zoom.w + 16
    xs[#xs + 1] = zoom.x + zoom.w + 48
  end
  for _, f in ipairs({ 0.5, 0.65, 0.35, 0.8 }) do xs[#xs + 1] = frame.x + frame.w * f end
  local points = {}
  for _, x in ipairs(xs) do
    if x > frame.x + 4 and x < frame.x + frame.w - 4 then points[#points + 1] = point(x, y) end
  end
  return points
end

-- Whether a press and a nudge of dx points took the window: its frame, read
-- after, moved toward the pointer. Some apps' windows follow no synthetic
-- drag wherever it lands (Dictionary, Stickies: vc's grab probes at 45acc46),
-- so a hit test on the bar is not the proof. True, or nil and why.
function P.hold_took(before, after, dx)
  if not after then return nil, "its frame could not be read after the nudge" end
  local moved = after.x - before.x
  if (dx > 0 and moved >= 1) or (dx < 0 and moved <= -1) then return true end
  return nil, string.format("its frame did not follow the pointer (x %d to %d after a nudge of %d)",
    P.round(before.x), P.round(after.x), dx)
end

-- The symbolic hotkeys for Mission Control's "Move left a space" and "Move
-- right a space": the Move-space shortcut D21 presses.
P.MOVE_LEFT, P.MOVE_RIGHT = 79, 81

local MASKS = {
  { name = "shift", bit = 0x20000 },
  { name = "ctrl", bit = 0x40000 },
  { name = "alt", bit = 0x80000 },
  { name = "cmd", bit = 0x100000 },
  { name = "fn", bit = 0x800000 },
}

-- A symbolic hotkey's modifier mask as modifier names. Arithmetic rather than
-- bit operators, which Lua 5.1 lacks. An arrow key's mask carries fn, as a
-- real arrow key does, and it is kept.
function P.decode_mods(mask)
  local mods = {}
  for _, m in ipairs(MASKS) do
    if math.floor(mask / m.bit) % 2 == 1 then mods[#mods + 1] = m.name end
  end
  return mods
end

-- One shortcut from com.apple.symbolichotkeys as { id, keycode, mods }, or
-- nil and why. An absent entry is macOS's default, which cannot be read, so
-- it is refused rather than guessed.
function P.hotkey(prefs, id)
  if type(prefs) ~= "table" then return nil, "com.apple.symbolichotkeys could not be read" end
  local entry = (prefs.AppleSymbolicHotKeys or {})[tostring(id)]
  if type(entry) ~= "table" then
    return nil, string.format("symbolic hotkey %d is not set in com.apple.symbolichotkeys, so its key is macOS's"
      .. " default, which cannot be read; set it in Keyboard Shortcuts > Mission Control", id)
  end
  if not (entry.enabled == true or entry.enabled == 1) then
    return nil, string.format("symbolic hotkey %d is turned off in Keyboard Shortcuts > Mission Control", id)
  end
  local p = type(entry.value) == "table" and entry.value.parameters
  if type(p) ~= "table" or type(p[2]) ~= "number" or type(p[3]) ~= "number" then
    return nil, string.format("symbolic hotkey %d carries no keycode and modifier mask", id)
  end
  return { id = id, keycode = p[2], mods = P.decode_mods(p[3]) }
end

-- The spaces a display passes through from one space to another along its
-- order, the first step first, and the side they lie on; {} when they are the
-- same space; nil when either is not in the order.
function P.walk(order, from, to)
  local i, j
  for k, id in ipairs(order or {}) do
    if id == from then i = k end
    if id == to then j = k end
  end
  if not (i and j) then return nil end
  local steps, side = {}, (j > i) and "right" or "left"
  local d = (j > i) and 1 or -1
  local k = i
  while k ~= j do
    k = k + d
    steps[#steps + 1] = order[k]
  end
  return steps, side
end

-- The legs of one move (design.md, "Moving a window"), from where things are
-- now. now = { order = {[screen] = {ids}}, types = {[id] = type},
-- active = {[screen] = id} }; move = { screen, space, from_screen,
-- from_space }. Each leg is one of
--   { kind = "switch", screen, steps, side }  nothing held: show a desktop
--   { kind = "carry", screen, steps, side, from }  held: carry the window
--   { kind = "drag", from_screen, screen, space }  held: across displays
-- Returns the legs, {} when the window is already there, or nil and why.
function P.move_legs(now, move)
  local legs = {}
  local function switch(screen, to)
    local at = now.active[screen]
    if at == nil then
      return false, string.format("the space screen %s shows could not be read: %s", tostring(screen),
        tostring((now.active_error or {})[screen]))
    end
    if at == to then return true end
    local steps, side = P.walk(now.order[screen], at, to)
    if not steps then
      return false, string.format("screen %s shows space %s, which is not in its order", tostring(screen), tostring(at))
    end
    legs[#legs + 1] = { kind = "switch", screen = screen, steps = steps, side = side }
    return true
  end
  if not move.space then
    return nil, string.format("space %s of screen %s does not exist", tostring(move.ordinal), tostring(move.screen))
  end
  if move.from_screen == move.screen and move.from_space == move.space then return legs end
  local ok, why
  if move.from_screen ~= move.screen then
    ok, why = switch(move.screen, move.space)
    if not ok then return nil, why end
    ok, why = switch(move.from_screen, move.from_space)
    if not ok then return nil, why end
    legs[#legs + 1] = { kind = "drag", from_screen = move.from_screen, screen = move.screen, space = move.space }
    return legs
  end
  ok, why = switch(move.screen, move.from_space)
  if not ok then return nil, why end
  local steps, side = P.walk(now.order[move.screen], move.from_space, move.space)
  if not steps then
    return nil, string.format("space %s or %s is not in screen %s's order", tostring(move.from_space),
      tostring(move.space), tostring(move.screen))
  end
  for _, id in ipairs(steps) do
    if not P.is_user_space(now.types[id]) then
      return nil, string.format("a %s space (%s) lies between space %s and space %s, and a held window cannot be"
        .. " carried into one", tostring(now.types[id]), tostring(id), tostring(move.from_space), tostring(move.space))
    end
  end
  legs[#legs + 1] = { kind = "carry", screen = move.screen, steps = steps, side = side, from = move.from_space }
  return legs
end

-- Whether a moved window is where it was sent (design.md, "Moving a
-- window"), from the readback taken 0.5 s after letting go: { window_spaces,
-- shown, listed_at_destination, listed_at_origin, origin } and an `errors`
-- list of what could not be read. A gesture has no return value, so this is
-- the only evidence. `moved` is false when the window had no legs to go
-- (it was there already), and then only its space is asked of it. Returns
-- "done" or "failed", and why.
function P.move_verdict(rb, op, moved)
  if rb.errors and #rb.errors > 0 then
    return "failed", "the readback could not be read: " .. table.concat(rb.errors, "; ")
  end
  local spaces = rb.window_spaces or {}
  local alone = #spaces == 1 and spaces[1] == op.space
  if not moved then
    if alone then return "done", nil end
    return "failed", string.format("planned onto space %s, where it already was, and it is on {%s}",
      tostring(op.space), table.concat(spaces, ","))
  end
  if alone and rb.shown == op.space and rb.listed_at_destination and not rb.listed_at_origin then
    return "done", nil
  end
  return "failed", string.format(
    "the readback disagrees: the window is on {%s}, screen %s shows %s, listed at space %s: %s, at its origin %s: %s",
    table.concat(spaces, ","), tostring(op.screen), tostring(rb.shown), tostring(op.space),
    tostring(rb.listed_at_destination), tostring(rb.origin), tostring(rb.listed_at_origin))
end

-- Whether apply must take the pointer: any move, or a place for a window on
-- a desktop its display is not showing, since a window there cannot be
-- placed until its desktop is shown (D21's switch, with nothing held).
function P.needs_hand(ops, world)
  -- Hidden means listed on no space being shown: a window on every space is
  -- on the shown one too.
  local listed = P.listings(world)
  for _, op in ipairs(ops or {}) do
    if op.op == "move" then return true end
    if op.op == "place" and listed[op.window] and not listed[op.window].shown then return true end
  end
  return false
end

-- What `open -b` said, as a launch's status: nil when it ran, "skipped"
-- when the bundle id names nothing on this Mac (its words, measured on macOS
-- 27.0.1), and "failed" for anything else, never quietly a skip.
function P.launch_verdict(ran, said, rc)
  if ran then return nil end
  said = string.gsub(said or "", "%s+$", "")
  if string.find(said, "determine the application with bundle identifier", 1, true) then
    return "skipped", "not installed: " .. said
  end
  return "failed", string.format("open -b exited %s: %s", tostring(rc), said)
end

-- ------------------------------------------------------------- the report

-- Results that stop every entry after them: a phase of apply failed once
-- things had begun to change, so no entry without a result of its own can
-- be reported placed. The engine records every such failure as op "phase",
-- never under an op's own kind.
local BLANKET = { phase = true }

-- What apply says per desk entry (design.md, apply step 11), from the ops it
-- planned and the results execute returned, each result carrying its op's
-- `op`, `path`, `bundle`, `status` and `reason`. A launch speaks for every
-- entry of its app. Returns the report lines and the exit code: 0 when every
-- entry is placed, 1 when any is skipped, unseen or failed, or when any op
-- failed whatever entry it served.
function P.apply_report(desk, results)
  local by_path, by_app, loose, blanket = {}, {}, {}, {}
  for _, r in ipairs(results or {}) do
    if BLANKET[r.op] and r.status ~= "done" then blanket[#blanket + 1] = tostring(r.reason) end
    if r.op == "launch" then
      by_app[app_key(r.bundle)] = r
    elseif r.path and string.find(r.path, "%.apps%[") then
      local list = by_path[r.path] or {}
      list[#list + 1] = r
      by_path[r.path] = list
    elseif r.status ~= "done" then
      loose[#loose + 1] = r
    end
  end
  local lines, code = {}, 0
  -- In the desk's own order, which is how a person reads it.
  local ordered = {}
  for di, d in ipairs(desk.displays or {}) do
    for si, sp in ipairs(d.spaces or {}) do
      for ai, a in ipairs(sp.apps or {}) do ordered[#ordered + 1] = { app = a, path = path_of(di, si, ai) } end
    end
  end
  for _, e in ipairs(ordered) do
    local launch = by_app[app_key(e.app.app)]
    local outcome, why, moved = "placed", {}, false
    if launch and launch.status ~= "done" then
      outcome = launch.status
      why[#why + 1] = tostring(launch.reason)
    end
    for _, r in ipairs(by_path[e.path] or {}) do
      if r.status == "done" then
        if r.op == "move" then moved = true end
      elseif outcome == "placed" or r.status == "failed" then
        outcome = r.status
        why[#why + 1] = tostring(r.reason)
      end
    end
    if outcome == "placed" and #blanket > 0 then
      outcome = "failed"
      why[#why + 1] = "not finished: " .. table.concat(blanket, "; ")
    end
    if outcome == "placed" then
      if launch then outcome = "launched and placed" elseif moved then outcome = "moved and placed" end
    else
      code = 1
    end
    local name = e.app.window and string.format("%s %q", e.app.app, e.app.window) or e.app.app
    lines[#lines + 1] = string.format("%s (%s): %s%s", name, e.path, outcome,
      (#why > 0) and (": " .. table.concat(why, "; ")) or "")
  end
  -- A note is said and counts against nothing: something apply left as it
  -- found it on purpose, such as focus on a desktop no longer shown.
  for _, r in ipairs(loose) do
    if r.status ~= "note" then code = 1 end
    lines[#lines + 1] = string.format("%s%s: %s: %s", tostring(r.op), r.path and (" (" .. r.path .. ")") or "",
      tostring(r.status), tostring(r.reason))
  end
  return lines, code
end

-- ------------------------------------------------------------- discover

-- A window title as a pattern that matches exactly that title: its magic
-- characters escaped, and anchored at both ends, because plan matches with
-- string.find, which finds a substring, and "Inbox" must not take
-- "Inbox - 2 messages".
local function escape_pattern(text)
  return (string.gsub(text, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1"))
end

local function exact_pattern(text)
  return "^" .. escape_pattern(text) .. "$"
end

-- The patterns discover tries for a window it pins, loosest first (ST0028):
-- the title's core, unanchored, then anchored at its end, then the title
-- exact. The core is the title without its leading run of characters other
-- than ASCII letters and digits, so a glyph a terminal puts in front of a
-- title (Claude Code's working glyph, a shell's -) does not hold the pattern
-- to one moment. The class is spelled out rather than %w, which follows the
-- C library's locale, where a byte of a UTF-8 glyph may read as a letter.
local function pin_candidates(title)
  local core = string.gsub(title, "^[^A-Za-z0-9]+", "")
  local candidates = {}
  if core ~= "" then
    candidates[#candidates + 1] = escape_pattern(core)
    candidates[#candidates + 1] = escape_pattern(core) .. "$"
  end
  candidates[#candidates + 1] = exact_pattern(title)
  return candidates
end

-- One axis of a window snapped to the grid: the nearest cell edges for its
-- start and end, the larger distance in points between an edge and the cell
-- edge it was given, and whether either edge sat a quarter of a cell or more
-- from any cell edge, which is a window spanning part of a cell.
local function snap_axis(start, length, origin, extent, cells)
  local cell = extent / cells
  local a = (start - origin) / cell
  local b = (start + length - origin) / cell
  local a0 = clamp(round(a), 0, cells - 1)
  local b0 = clamp(round(b), a0 + 1, cells)
  local off_a = math.abs(start - (origin + a0 * cell))
  local off_b = math.abs((start + length) - (origin + b0 * cell))
  local partial = math.abs(a - round(a)) >= 0.25 or math.abs(b - round(b)) >= 0.25
  return a0, b0 - a0, math.max(off_a, off_b), partial
end

-- The layout a window's frame snaps to on a screen and grid, its misfit in
-- whole points, and whether it spans part of a cell.
function P.snap(frame, screen_frame, grid)
  local x, w, mx, px = snap_axis(frame.x, frame.w, screen_frame.x, screen_frame.w, grid.w)
  local y, h, my, py = snap_axis(frame.y, frame.h, screen_frame.y, screen_frame.h, grid.h)
  return string.format("%d,%d %dx%d", x, y, w, h), round(math.max(mx, my)), px or py
end

-- The bundle ids discover never records: Hammerspoon's own windows are the
-- engine, not the arrangement.
-- Keyed by app_key.
P.NOT_RECORDED = { ["org.hammerspoon.hammerspoon"] = true }

local function sort_apps(apps)
  table.sort(apps, function(p, q)
    local lp, lq = P.parse_layout(p.layout), P.parse_layout(q.layout)
    local yp, yq = lp and lp.y or -1, lq and lq.y or -1
    if yp ~= yq then return yp < yq end
    local xp, xq = lp and lp.x or -1, lq and lq.x or -1
    if xp ~= xq then return xp < xq end
    if p.app ~= q.app then return p.app < q.app end
    return (p.title or "") < (q.title or "")
  end)
end

-- A desk from a world (WP-04): what discover prints. PURE, like plan.
--
-- options: grid ("WxH", default 8x4, D19) and name (the desk's name). Returns
-- the desk and the report lines that say what was not recorded and why --
-- minimized windows, windows on every space, windows Accessibility could not
-- name, a window whose title cannot tell it from its app's others, windows
-- that span part of a cell, and the Dock bindings, which a v1 desk does not
-- hold. Every display is recorded with all four match fields; a display's
-- desk name is its position, which the validator needs unique.
function P.desk_from_world(world, options)
  options = options or {}
  local grid_text = options.grid or "8x4"
  local grid = P.parse_grid(grid_text)
  if not grid or grid.w < 1 or grid.h < 1 then return nil, "the grid is not WxH: " .. tostring(grid_text) end
  local notes = {}
  local function note(fmt, ...) notes[#notes + 1] = string.format(fmt, ...) end

  -- What observe could not read is refused, never written down as empty: a
  -- desk that says "nothing here" where the engine could not look would be
  -- applied as if it were true.
  local unread_refusal = unread(world)
  if unread_refusal then return nil, unread_refusal end

  -- A window listed on more than one space is on every space; it is no
  -- space's, so it is said and left out.
  local listed = P.listings(world)

  -- The primary first, then the rest by position and uuid, so the same world
  -- always gives the same desk.
  local screens = {}
  for _, s in ipairs(world.screens or {}) do screens[#screens + 1] = s end
  table.sort(screens, function(a, b)
    if (a.primary and true or false) ~= (b.primary and true or false) then return a.primary and true or false end
    if tostring(a.position) ~= tostring(b.position) then return tostring(a.position) < tostring(b.position) end
    return tostring(a.uuid) < tostring(b.uuid)
  end)

  -- How many windows each app has across the whole world decides whether its
  -- entries need a window pattern, and how many of them share each title
  -- decides whether a pattern can tell them apart. Both count what plan can
  -- claim, by the same test, once per window wherever it is listed, a window
  -- on every space included: plan gives a bare entry every claimable window
  -- of its app on every display, and a title pattern every one carrying that
  -- title, so anything counted narrower here would make the discovered desk
  -- claim windows it never recorded.
  local per_app, titles, counted = {}, {}, {}
  for _, s in ipairs(world.screens or {}) do
    for _, sp in ipairs(s.spaces or {}) do
      for _, w in ipairs(sp.windows or {}) do
        if claimable(w) and w.bundle and not counted[w.id] then
          counted[w.id] = true
          local app = app_key(w.bundle)
          per_app[app] = (per_app[app] or 0) + 1
          titles[app] = titles[app] or {}
          titles[app][#titles[app] + 1] = w.title or ""
        end
      end
    end
  end

  -- The loosest pattern that takes exactly one of the app's claimable
  -- windows, as plan matches it, or nil when none tells this one apart.
  local function pin(app, title)
    if title == "" then return nil end
    for _, pattern in ipairs(pin_candidates(title)) do
      local hits = 0
      for _, t in ipairs(titles[app]) do
        if string.find(t, pattern) then hits = hits + 1 end
      end
      if hits == 1 then return pattern end
    end
    return nil
  end

  local desk = { desk = options.name or "discovered", grid = grid_text, displays = {} }
  local used_names = {}
  for di, s in ipairs(screens) do
    local label = tostring(s.position or ("display-" .. di))
    if used_names[label] then label = label .. "-" .. di end
    used_names[label] = true
    local display = {
      name = label,
      match = { uuid = s.uuid, name = P.panel_name(s.name), size = size_of(s), position = s.position },
      spaces = {},
    }

    -- Gather each desktop's windows, and file each full-screen space's window
    -- under the desktop before it in Mission Control order (D11).
    local desktops, current = {}, nil
    local pending_fullscreen = {}
    for _, sp in ipairs(s.spaces or {}) do
      if P.is_user_space(sp.type) then
        current = { space = sp, windows = {} }
        desktops[#desktops + 1] = current
        for _, w in ipairs(pending_fullscreen) do current.windows[#current.windows + 1] = w end
        pending_fullscreen = {}
      end
      local named, recorded, minimized, unnamed, everywhere, own, other = 0, 0, 0, 0, 0, 0, 0
      for _, w in ipairs(sp.windows or {}) do
        if not w.named then
          unnamed = unnamed + 1
        else
          named = named + 1
          if listed[w.id].count > 1 then
            everywhere = everywhere + 1
          elseif P.NOT_RECORDED[app_key(w.bundle)] then
            own = own + 1
          elseif w.minimized then
            minimized = minimized + 1
          elseif claimable(w) and w.bundle then
            recorded = recorded + 1
            local entry = { win = w, fullscreen = not P.is_user_space(sp.type) }
            if current then current.windows[#current.windows + 1] = entry
            else pending_fullscreen[#pending_fullscreen + 1] = entry end
          else
            other = other + 1
          end
        end
      end
      note("%s space %d (%s): %d windows, %d named, %d recorded%s%s%s%s%s", label, sp.ordinal or 0, tostring(sp.type),
        #(sp.windows or {}), named, recorded,
        other > 0 and string.format(", %d not standard windows", other) or "",
        minimized > 0 and string.format(", %d minimized (no frame worth keeping)", minimized) or "",
        everywhere > 0 and string.format(", %d on every space", everywhere) or "",
        own > 0 and string.format(", %d Hammerspoon's own", own) or "",
        unnamed > 0 and string.format(", %d Accessibility could not name", unnamed) or "")
    end
    -- A full-screen window goes under the desktop before it; one with no
    -- desktop before it waits for the next, and one left over here means the
    -- display has no desktop to file it under.
    if #pending_fullscreen > 0 then
      note("%s: %d full-screen window(s) and no desktop to file them under, so not recorded", label, #pending_fullscreen)
    end

    for si, d in ipairs(desktops) do
      local apps = {}
      for _, e in ipairs(d.windows) do
        local w = e.win
        local app = { app = w.bundle }
        if per_app[app_key(w.bundle)] > 1 then
          local title = w.title or ""
          local pattern = pin(app_key(w.bundle), title)
          if not pattern then
            note("%s desktop %d: a window of %s is not recorded: its title %q does not tell it from the app's others",
              label, si, w.bundle, title)
            app = nil
          else
            app.window = pattern
            note("%s desktop %d: %s %q pinned as %q", label, si, w.bundle, title, pattern)
          end
        end
        if app then
          if e.fullscreen then
            app.layout = "fullscreen"
          else
            local layout, misfit, partial = P.snap(w.frame, s.frame, grid)
            app.layout = layout
            if misfit > 0 then app.misfit = string.format("%dpx", misfit) end
            if partial then
              note("%s desktop %d: %s %q spans part of a cell; snapped to %s, %dpx off", label, si, w.bundle,
                w.title or "", layout, misfit)
            end
          end
          app.title = w.title
          apps[#apps + 1] = app
        end
      end
      sort_apps(apps)
      for _, a in ipairs(apps) do a.title = nil end
      display.spaces[#display.spaces + 1] = { apps = apps }
    end
    desk.displays[#desk.displays + 1] = display
  end

  local bindings_why = bindings_unread(world)
  if bindings_why then
    note("%s; a v1 desk records none of them", bindings_why)
  else
    local all, one, other = 0, 0, 0
    for _, b in ipairs(world.app_bindings or {}) do
      if b.target == "AllSpaces" then all = all + 1
      elseif type(b.target) == "string" then one = one + 1
      else other = other + 1 end
    end
    note("%d Dock bindings: %d to all spaces, %d to one space%s; a v1 desk records none of them",
      #(world.app_bindings or {}), all, one, other > 0 and string.format(", %d unreadable", other) or "")
  end
  return desk, notes
end

-- ------------------------------------------------------------- diff

-- One line per op, as diff prints it: what apply would do, and why.
local DESCRIBE = {
  create_space = function(op) return "create a space on " .. tostring(op.screen) end,
  launch = function(op) return "launch " .. tostring(op.bundle) end,
  move = function(op)
    return string.format("move window %s to space %s of %s", tostring(op.window), tostring(op.ordinal), tostring(op.screen))
  end,
  place = function(op)
    return string.format("place window %s at %d,%d %dx%d", tostring(op.window), op.frame.x, op.frame.y, op.frame.w, op.frame.h)
  end,
  unseen = function(op) return "unseen " .. tostring(op.bundle) end,
  not_launched = function(op) return "not launching " .. tostring(op.bundle) end,
  gone = function(op) return "gone " .. tostring(op.bundle) end,
  unmovable = function(op) return "not moving window " .. tostring(op.window) end,
  no_space = function(op) return "no space for window " .. tostring(op.window) end,
  pending = function(op) return "after the new space, window " .. tostring(op.window) end,
}

function P.plan_report(ops)
  local lines = {}
  for _, op in ipairs(ops or {}) do
    local describe = DESCRIBE[op.op]
    local what = describe and describe(op) or tostring(op.op)
    lines[#lines + 1] = string.format("%s%s: %s", what, op.path and (" (" .. op.path .. ")") or "", tostring(op.reason))
  end
  if #lines == 0 then lines[1] = "no change: this machine already matches the desk" end
  return lines
end

return P
