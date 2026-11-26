-- mc_test.lua: the pure part of mc.lua, arngz's own Mission Control finder,
-- under plain Lua, over plain-table Dock trees.
--
-- Run by arngz.bats under whichever of lua5.4, lua or luajit is present:
--   <lua> opt/arngz/test/mc_test.lua <path to opt/arngz/lib/mc.lua>
-- It prints one line per check and exits 1 if any failed.

local MC = dofile(arg[1] or "opt/arngz/lib/mc.lua")

local failed, passed = 0, 0
local function check(name, ok, detail)
  if ok then
    passed = passed + 1
    print("  ok    " .. name)
  else
    failed = failed + 1
    print("  FAIL  " .. name .. (detail and (": " .. detail) or ""))
  end
end

-- A tree node: its attributes, and its children.
local function node(attrs, kids)
  attrs.kids = kids or {}
  return attrs
end

local A = {
  kids = function(el) return el.kids end,
  attr = function(el, name) return el[name] end,
}

-- A Dock with the Dock's list, and Mission Control's group for two displays:
-- display 1 with tiles t1, t2, t3 and the add button; display 2 with one tile.
local function tiles(prefix, n)
  local out = {}
  for i = 1, n do out[i] = node({ name = prefix .. i }) end
  return out
end

local function mc_display(id, n)
  return node({ AXIdentifier = "mc.display", AXDisplayID = id }, {
    node({ AXIdentifier = "mc.spaces" }, {
      node({ AXIdentifier = "mc.spaces.list" }, tiles("d" .. id .. "t", n)),
      node({ AXIdentifier = "mc.spaces.add", name = "add" .. id }),
    }),
  })
end

local function dock(open)
  local kids = { node({ AXRole = "AXList", name = "the Dock's list" }) }
  if open then
    kids[#kids + 1] = node({ AXIdentifier = "mc", name = "group" }, { mc_display(2, 1), mc_display(1, 3) })
  end
  return node({ AXRole = "AXApplication" }, kids)
end

print("the group")
do
  check("a closed Dock has no group", MC.find_group(A, dock(false)) == nil)
  local g = MC.find_group(A, dock(true))
  check("an open Dock's group is found (macOS 26)", g and g.name == "group", g and g.name)
  check("is_group takes an element that holds an mc.display", MC.is_group(A, node({}, { mc_display(1, 1) })))
  check("is_group refuses an element with no mc.display", not MC.is_group(A, node({ AXIdentifier = "mc" })))
  check("is_group refuses the Dock's list", not MC.is_group(A, node({ AXRole = "AXList" })))
end

-- WindowManager on macOS 27 (mcdiag2): its application element holds the
-- mc.display groups itself, beside buttons for each app's windows.
local function window_manager(open)
  local kids = {}
  if open then
    kids = { mc_display(2, 1), mc_display(1, 3) }
    table.insert(kids[2].kids, 1, node({ AXRole = "AXButton", AXIdentifier = "com.example.app.space.1" }))
  end
  return node({ AXRole = "AXApplication", name = "wm" }, kids)
end

print("WindowManager")
do
  check("a closed WindowManager has no group", MC.find_group(A, window_manager(false)) == nil)
  local g = MC.find_group(A, window_manager(true))
  check("an open WindowManager is its own group", g and g.name == "wm", g and g.name)
  local list = MC.locate(A, g, 1, "list")
  check("its display 1 tiles are found past an app's button", list and #list.kids == 3, list and #list.kids)
  local add = MC.locate(A, g, 2, "add")
  check("its display 2 add button is found", add and add.name == "add2", add and add.name)
end

print("locate")
do
  local g = MC.find_group(A, dock(true))
  local add = MC.locate(A, g, 1, "add")
  check("the add button of display 1", add and add.name == "add1", add and add.name)
  local list = MC.locate(A, g, 2, "list")
  check("the tiles of display 2", list and #list.kids == 1 and list.kids[1].name == "d2t1")
  local none, why = MC.locate(A, g, 9, "add")
  check("a display not in the group gives hs.spaces' words", none == nil and why == MC.NO_DISPLAY, why)
  local bare = node({ AXIdentifier = "mc" }, { node({ AXIdentifier = "mc.display", AXDisplayID = 1 }) })
  local _, swhy = MC.locate(A, bare, 1, "list")
  check("a display with no mc.spaces says so", swhy == "unable to locate mc.spaces group for display", swhy)
  local noadd = node({ AXIdentifier = "mc" }, {
    node({ AXIdentifier = "mc.display", AXDisplayID = 1 }, { node({ AXIdentifier = "mc.spaces" }) }) })
  local _, awhy = MC.locate(A, noadd, 1, "add")
  check("a display with no add button says so", awhy == "unable to find target mc.spaces.add for display", awhy)
end

print("tiles")
do
  local list = MC.locate(A, MC.find_group(A, dock(true)), 1, "list")
  local t = MC.tile(A, list, 2)
  check("tile 2 of display 1", t and t.name == "d1t2", t and t.name)
  local none, why = MC.tile(A, list, #list.kids + 1)
  check("a tile past the last says so", none == nil and why ~= nil, why)
  check("index_of is a space's place in spacesForScreen's list", MC.index_of({ 5, 9, 7 }, 7) == 3)
  check("index_of a space not listed is nil", MC.index_of({ 5, 9 }, 7) == nil)
end

print("the reasons")
do
  local plan_path = arg[2]
  if plan_path then
    local P = dofile(plan_path)
    check("plan reads the group's reason as the Dock's", P.space_error_kind(MC.NO_GROUP) == "dock")
    check("plan reads the display's reason as gone", P.space_error_kind(MC.NO_DISPLAY) == "gone")
  else
    check("plan.lua's path is given as the second argument", false)
  end
end

print(string.format("mc_test: %d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
