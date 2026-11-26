-- mc.lua: arngz's own Mission Control finder (cc, 26 Nov 2026; design note
-- desks1125/mc-design.md, for ST6d8eed9 WP A and STca1b7f9 WP6).
--
-- hs.spaces (Hammerspoon 1.1.1) does every desktop edit through Mission
-- Control, and on macOS 27.2.1 its lookup never finds Mission Control's
-- group: it looks for a Dock child with AXIdentifier "mc", and macOS 27
-- shows Mission Control in WindowManager (desks1125/mcdiag2). This file does
-- the three edits arngz makes (add, show, remove) with its own lookup,
-- through hs.axuielement, a public module (D15): WindowManager first, then
-- the Dock, so macOS 26 keeps working. Reading the desktops stays with
-- hs.spaces.
--
-- The pure part walks a Dock tree through an accessor A = { kids, attr }, so
-- mc_test.lua gives it plain tables. The impure part opens Mission Control,
-- waits for the group, acts, and closes Mission Control on every path.
--
-- The reasons keep hs.spaces' words, so plan.lua's P.space_error_kind reads
-- them with no change.

local MC = {}

MC.NO_GROUP = "unable to get Mission Control data from the Dock"
MC.NO_DISPLAY = "no display with specified id found"
MC.NOT_CLOSED = "Mission Control did not close"
MC.OPEN_SECONDS = 4      -- how long Mission Control's group may take to appear, or to go after a close
MC.CLOSING_SECONDS = 1   -- how long a close already under way may take before close() toggles (Escape took 637 ms, mcdiag2)
MC.SETTLE_SECONDS = 0.3  -- after it appears, before a button is pressed (hs.spaces' MCwaitTime)
MC.POLL_US = 50000       -- the group is looked for this often, in microseconds

-- ------------------------------------------------------------- pure

-- The first child of EL that WANT accepts, or nil.
local function child(A, el, want)
  for _, k in ipairs(A.kids(el) or {}) do
    if want(k) then return k end
  end
  return nil
end

local function with_id(A, id)
  return function(k) return A.attr(k, "AXIdentifier") == id end
end

-- Whether EL is Mission Control's group: the element that holds one
-- mc.display per display. The second diagnostic (desks1125/mcdiag2, 26 Nov
-- 2026) read it on macOS 27.2.1 as WindowManager's application element
-- itself. On macOS 26 it is the Dock's child "mc", as hs.spaces looks for,
-- and that child holds the same mc.display groups.
function MC.is_group(A, el)
  return child(A, el, with_id(A, "mc.display")) ~= nil
end

-- Mission Control's group under ROOT, an owner's application element: ROOT
-- itself, or one of its children. nil while Mission Control is closed.
function MC.find_group(A, root)
  if MC.is_group(A, root) then return root end
  return child(A, root, function(k) return MC.is_group(A, k) end)
end

-- In GROUP, the node WANT names for the display with DISPLAY_ID: "add", the
-- button that adds a desktop, or "list", the group of desktop tiles in the
-- order spacesForScreen lists the desktops. nil and a reason if it is not
-- there.
function MC.locate(A, group, display_id, want)
  local display = child(A, group, function(k)
    return A.attr(k, "AXIdentifier") == "mc.display" and A.attr(k, "AXDisplayID") == display_id
  end)
  if not display then return nil, MC.NO_DISPLAY end
  local spaces = child(A, display, with_id(A, "mc.spaces"))
  if not spaces then return nil, "unable to locate mc.spaces group for display" end
  local id = want == "add" and "mc.spaces.add" or "mc.spaces.list"
  local node = child(A, spaces, with_id(A, id))
  if not node then return nil, string.format("unable to find target %s for display", id) end
  return node
end

-- The tile at INDEX in a "list" node, or nil and a reason.
function MC.tile(A, list, index)
  local tile = (A.kids(list) or {})[index]
  if not tile then return nil, string.format("no desktop tile %s in Mission Control", tostring(index)) end
  return tile
end

-- The place of SPACE in IDS (spacesForScreen's list), or nil.
function MC.index_of(ids, space)
  for i, id in ipairs(ids or {}) do
    if id == space then return i end
  end
  return nil
end

-- One AX action on EL, answered as hs.spaces answers: true, or nil and a
-- reason. hs.axuielement's performAction answers the element itself, or false
-- with no reason, or nil and a message; and a tile with no such action (the
-- only desktop on a display has no AXRemoveDesktop, mcdiag2) raises. ic's F1.
function MC.press(el, action)
  local ok, res, err = pcall(function() return el:performAction(action) end)
  if not ok then return nil, tostring(res) end
  if res then return true end
  return nil, err and tostring(err) or string.format("Mission Control refused %s", action)
end

-- Waits up to SECONDS until SHOWN() is false: true, or nil and
-- MC.NOT_CLOSED. CLOCK = { now (ns), sleep (us) }. A tile's press returns
-- while Mission Control is still closing, and an edit that came next could
-- find the closing group and act on it (probe r2, runs/20261126T073026Z).
function MC.await_closed(shown, clock, seconds)
  local deadline = clock.now() + seconds * 1e9
  while shown() do
    if clock.now() >= deadline then return nil, MC.NOT_CLOSED end
    clock.sleep(MC.POLL_US)
  end
  return true
end

-- Closes Mission Control if SHOWN() says it shows, by TOGGLE, and waits
-- until it has: true, or nil and MC.NOT_CLOSED. It waits CLOSING_SECONDS
-- first and toggles only if it still shows, so a Mission Control that is
-- already closing (a press that took effect but reported a fault) is not
-- opened again (ic's F1 on 597fef67).
function MC.shut(shown, toggle, clock)
  if MC.await_closed(shown, clock, MC.CLOSING_SECONDS) then return true end
  toggle()
  return MC.await_closed(shown, clock, MC.OPEN_SECONDS)
end

-- A reason, with a second one after it if there is one.
local function joined(why, more)
  if not more then return why end
  return tostring(why) .. "; and " .. more
end

-- ------------------------------------------------------------- impure

-- The accessor over live AX elements.
local AX = {
  kids = function(el) return el:attributeValue("AXChildren") or {} end,
  attr = function(el, name) return el:attributeValue(name) end,
}

local function now() return hs.timer.absoluteTime() end

-- The processes Mission Control's group is looked for in, in order:
-- WindowManager on macOS 27, then the Dock, which held it before.
MC.OWNERS = { "com.apple.WindowManager", "com.apple.dock" }

-- The application elements of the owners that run.
local function owners()
  local out = {}
  for _, bundle in ipairs(MC.OWNERS) do
    local app = hs.application.get(bundle)
    local el = app and hs.axuielement.applicationElement(app)
    if el then out[#out + 1] = el end
  end
  return out
end

-- Mission Control's group in the first owner that shows it, or nil.
local function find_any(roots)
  for _, root in ipairs(roots) do
    local group = MC.find_group(AX, root)
    if group then return group end
  end
  return nil
end

-- Whether Mission Control shows now, read only from the owners' mc.display
-- groups, never from other windows: the probe's mc_before and mc_after.
function MC.shown()
  return find_any(owners()) ~= nil
end

-- Opens Mission Control as hs.spaces does. If the diagnostic shows that only
-- the keyboard opens it, this is the one place that changes.
function MC.open()
  hs.spaces.toggleMissionControl()
end

local CLOCK = { now = now, sleep = function(us) hs.timer.usleep(us) end }

local function shown_in(roots)
  return function() return find_any(roots) ~= nil end
end

-- Waits until no owner shows the group: true, or nil and a reason.
local function closed(roots)
  return MC.await_closed(shown_in(roots), CLOCK, MC.OPEN_SECONDS)
end

-- Closes Mission Control, if its group is there and is not already closing,
-- and waits until it has.
local function close(roots)
  return MC.shut(shown_in(roots), MC.open, CLOCK)
end

-- The group, waited for up to OPEN_SECONDS on the monotonic clock.
local function wait_group(roots)
  local deadline = now() + MC.OPEN_SECONDS * 1e9
  repeat
    local group = find_any(roots)
    if group then return group end
    hs.timer.usleep(MC.POLL_US)
  until now() >= deadline
  return find_any(roots)
end

local function screen_id(uuid)
  for _, s in ipairs(hs.screen.allScreens()) do
    if s:getUUID() == uuid then return s:id() end
  end
  return nil
end

-- Opens Mission Control, finds WANT for the display UUID, calls ACT on it,
-- and closes Mission Control on every path, a raise in ACT included. ACT
-- returns true, or nil and a reason; CLOSES says ACT closes it itself. It
-- returns only once Mission Control has closed; one that does not close
-- fails the step. A Mission Control that shows at the start (one the person
-- opened, or one an earlier step could not close) is closed first, so a
-- group that is closing is never acted on; one that will not close fails
-- this step too (ic's N2 on 597fef67).
local function with_mc(uuid, want, act, closes)
  local id = screen_id(uuid)
  if not id then return nil, MC.NO_DISPLAY end
  local roots = owners()
  if #roots == 0 then return nil, "neither WindowManager nor the Dock is running" end
  local was_shut, werr = close(roots)
  if not was_shut then return nil, werr end
  MC.open()
  local group = wait_group(roots)
  if not group then return nil, MC.NO_GROUP end
  hs.timer.usleep(math.floor(MC.SETTLE_SECONDS * 1e6))
  local node, nerr = MC.locate(AX, group, id, want)
  if not node then
    local _, cerr = close(roots)
    return nil, joined(nerr, cerr)
  end
  local ok, res, why = pcall(act, node)
  local shut, cerr
  if ok and res and closes then
    shut, cerr = closed(roots)
  else
    shut, cerr = close(roots)
  end
  if not ok then return nil, joined(tostring(res), cerr) end
  if not res then return nil, joined(why, cerr) end
  if not shut then return nil, cerr end
  return res
end

-- As hs.spaces.addSpaceToScreen(uuid, true).
function MC.add_space(uuid)
  return with_mc(uuid, "add", function(add)
    return MC.press(add, "AXPress")
  end)
end

-- The tile of SPACE, by its place in spacesForScreen, as hs.spaces finds it.
local function on_tile(space, action, closes)
  local uuid = hs.spaces.spaceDisplay(space)
  if not uuid then return nil, "space not found in managed displays" end
  local index = MC.index_of(hs.spaces.spacesForScreen(uuid), space)
  if not index then return nil, "space not found in managed displays" end
  return with_mc(uuid, "list", function(list)
    local tile, terr = MC.tile(AX, list, index)
    if not tile then return nil, terr end
    return MC.press(tile, action)
  end, closes)
end

-- As hs.spaces.gotoSpace(space): pressing a tile shows it and closes
-- Mission Control.
function MC.goto_space(space)
  return on_tile(space, "AXPress", true)
end

-- As hs.spaces.removeSpace(space, true). The checks hs.spaces makes first (the
-- only user desktop, the desktop shown) are WP A's proof's, before it calls.
function MC.remove_space(space)
  return on_tile(space, "AXRemoveDesktop", false)
end

return MC
