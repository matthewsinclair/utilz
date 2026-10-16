-- plan_test.lua: AT-03.2, the pure planner, under plain Lua (ST0026 D12).
--
-- Run by arngz.bats under whichever of lua5.4, lua or luajit is present:
--   <lua> opt/arngz/test/plan_test.lua <path to opt/arngz/lib/plan.lua>
-- It prints one line per check and exits 1 if any failed. Every world here is
-- built from one base that already matches the base desk, so each test changes
-- exactly one thing and the ops it expects can only come from that change.

local plan_path = arg[1] or "opt/arngz/lib/plan.lua"
local P = dofile(plan_path)

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

local function ops_text(ops)
  local parts = {}
  for _, op in ipairs(ops or {}) do
    parts[#parts + 1] = op.op .. "(" .. tostring(op.window or op.bundle or op.screen or "") .. ")"
  end
  return "[" .. table.concat(parts, ", ") .. "]"
end

local function kinds(ops)
  local parts = {}
  for _, op in ipairs(ops or {}) do parts[#parts + 1] = op.op end
  return table.concat(parts, ",")
end

-- ------------------------------------------------------------- fixtures

-- One display, 1200x800 visible, a 12x8 grid, so a cell is 100x100 points and
-- every frame below can be checked by eye.
local function base_desk()
  return {
    desk = "base",
    grid = "12x8",
    displays = {
      {
        name = "left",
        match = { uuid = "SCREEN-A", name = "VY229HF", size = "1200x825", position = "main" },
        spaces = {
          { name = "comms", apps = {
            { app = "com.apple.mail", layout = "0,0 6x8" },
            { app = "com.apple.Safari", layout = "6,0 6x8" },
          } },
          { name = "code", apps = {
            { app = "com.microsoft.VSCode", window = "Utilz", layout = "0,0 12x8" },
          } },
        },
      },
    },
  }
end

local function win(id, bundle, title, x, y, w, h)
  return { id = id, bundle = bundle, title = title, frame = { x = x, y = y, w = w, h = h },
    named = true, standard = true, minimized = false }
end

-- The world as observe() records it, with every window already where the base
-- desk puts it.
local function base_world()
  return {
    screens = {
      {
        uuid = "SCREEN-A", name = "VY229HF", primary = true, position = "main",
        frame = { x = 0, y = 25, w = 1200, h = 800 },
        full_frame = { x = 0, y = 0, w = 1200, h = 825 },
        spaces = {
          { id = 11, ordinal = 1, type = "user", uuid = "SPACE-11", active = true, windows = {
            win(101, "com.apple.mail", "Inbox", 0, 25, 600, 800),
            win(102, "com.apple.Safari", "Docs", 600, 25, 600, 800),
          } },
          { id = 12, ordinal = 2, type = "user", uuid = "SPACE-12", active = false, windows = {
            win(103, "com.microsoft.VSCode", "arngz.lua - Utilz", 0, 25, 1200, 800),
          } },
        },
      },
    },
    apps_running = { "com.apple.mail", "com.apple.Safari", "com.microsoft.VSCode" },
    app_bindings = {},
  }
end

local function space(world, ordinal)
  return world.screens[1].spaces[ordinal]
end

-- ------------------------------------------------------------- geometry

print("geometry")
do
  local f = P.cell_frame({ x = 0, y = 25, w = 1200, h = 800 }, { w = 12, h = 8 }, { x = 6, y = 0, w = 6, h = 8 })
  check("a cell frame is the screen frame divided by the grid",
    f.x == 600 and f.y == 25 and f.w == 600 and f.h == 800,
    string.format("%d,%d %dx%d", f.x, f.y, f.w, f.h))
  local g = P.cell_frame({ x = 0, y = 0, w = 1000, h = 700 }, { w = 3, h = 3 }, { x = 1, y = 1, w = 1, h = 1 })
  check("a fractional cell rounds its edges, so adjacent cells share an edge",
    g.x == 333 and g.w == 334 and g.y == 233 and g.h == 234,
    string.format("%d,%d %dx%d", g.x, g.y, g.w, g.h))
  local l = P.parse_layout("2,3 4x5")
  check("parse_layout reads all four of x,y wxh",
    l ~= nil and l.x == 2 and l.y == 3 and l.w == 4 and l.h == 5)
  check("parse_layout reads nothing else",
    P.parse_layout("fullscreen") == nil and P.parse_layout("2,3 4x") == nil and P.parse_layout("2,3,4x5") == nil)
  local primary = { x = 0, y = 0, w = 1000, h = 800 }
  check("position: the primary screen is main", P.position(primary, primary) == "main")
  check("position: left", P.position({ x = -1920, y = 0, w = 1920, h = 1080 }, primary) == "left")
  check("position: right", P.position({ x = 1000, y = 0, w = 1920, h = 1080 }, primary) == "right")
  check("position: above", P.position({ x = 0, y = -1080, w = 1000, h = 1080 }, primary) == "above")
  check("position: below", P.position({ x = 0, y = 800, w = 1000, h = 1080 }, primary) == "below")
  check("position: a screen beside the primary but overlapping it vertically is level",
    P.position({ x = 1000, y = -300, w = 1000, h = 800 }, primary) == "right")
  check("position: centred above is plain above",
    P.position({ x = 200, y = -1080, w = 1000, h = 1080 }, primary) == "above")
  check("position: below-left and below-right",
    P.position({ x = -1500, y = 900, w = 1000, h = 800 }, primary) == "below-left"
      and P.position({ x = 1600, y = 900, w = 1000, h = 800 }, primary) == "below-right")
  -- hv's machine, measured 16 Oct 2026: two identical VY229HF panels above a
  -- 1800x1169 laptop. One word called both "above"; the compound form does not.
  local laptop = { x = 0, y = 0, w = 1800, h = 1169 }
  local p1 = P.position({ x = 914, y = -1080, w = 1920, h = 1080 }, laptop)
  local p2 = P.position({ x = -1021, y = -1080, w = 1920, h = 1080 }, laptop)
  check("position: hv's two panels are above-right and above-left, not both above",
    p1 == "above-right" and p2 == "above-left", tostring(p1) .. ", " .. tostring(p2))
  check("position: a screen over the primary is named overlapping",
    P.position({ x = 100, y = 100, w = 600, h = 400 }, primary) == "overlapping")
end

-- ------------------------------------------------------------- the planner

print("plan")

-- A world already matching the desk yields no ops.
do
  local ops, err = P.plan(base_desk(), base_world(), {})
  check("a world already matching the desk yields no ops", ops and #ops == 0, err or ops_text(ops))
end

-- A window a point or two off its cell is in place (FRAME_SLACK).
do
  local w = base_world()
  space(w, 1).windows[1].frame.w = 598
  local ops = P.plan(base_desk(), w, {})
  check("a frame within the slack yields no ops", ops and #ops == 0, ops_text(ops))
end

-- A window off its cell yields one place, to the cell's frame.
do
  local w = base_world()
  space(w, 1).windows[2].frame = { x = 300, y = 100, w = 500, h = 400 }
  local ops = P.plan(base_desk(), w, {})
  local op = ops and ops[1]
  check("a window off its cell yields exactly one place", kinds(ops) == "place", ops_text(ops))
  check("and the place carries the cell's frame, the window and the desk path",
    op and op.window == 102 and op.frame.x == 600 and op.frame.y == 25 and op.frame.w == 600
      and op.frame.h == 800 and op.path == "displays[0].spaces[0].apps[1]")
end

-- A window on the wrong space yields move then place.
do
  local w = base_world()
  local vscode = table.remove(space(w, 2).windows, 1)
  table.insert(space(w, 1).windows, vscode)
  local ops = P.plan(base_desk(), w, {})
  check("a window on the wrong space yields move then place", kinds(ops) == "move,place", ops_text(ops))
  check("the move names the window and the space ordinal on its display",
    ops and ops[1].window == 103 and ops[1].ordinal == 2 and ops[1].screen == "SCREEN-A")
  check("the move and the place each carry a reason", ops and ops[1].reason ~= nil and ops[2].reason ~= nil)
end

-- A display short of spaces yields create_space, and --no-create removes it.
do
  local w = base_world()
  local vscode = table.remove(w.screens[1].spaces, 2).windows[1]
  table.insert(space(w, 1).windows, vscode)
  local ops = P.plan(base_desk(), w, {})
  check("a display short of spaces yields create_space first",
    ops and ops[1] and ops[1].op == "create_space" and ops[1].screen == "SCREEN-A", ops_text(ops))
  check("and the window bound for the missing space is still moved and placed",
    kinds(ops) == "create_space,move,place", ops_text(ops))
  local without = P.plan(base_desk(), w, { no_create = true })
  check("--no-create removes create_space", kinds(without) == "move,place", ops_text(without))
end

-- A full-screen space takes no ordinal.
do
  local w = base_world()
  table.insert(w.screens[1].spaces, 2, { id = 99, ordinal = 2, type = "fullscreen", windows = {} })
  local ops = P.plan(base_desk(), w, {})
  check("a full-screen space between desktops takes no ordinal", ops and #ops == 0, ops_text(ops))
end

-- An app not running yields launch, and --no-launch removes it.
do
  local w = base_world()
  w.apps_running = { "com.apple.mail", "com.microsoft.VSCode" }
  table.remove(space(w, 1).windows, 2)
  local ops = P.plan(base_desk(), w, {})
  check("an app not running yields launch", kinds(ops) == "launch" and ops[1].bundle == "com.apple.Safari",
    ops_text(ops))
  local without = P.plan(base_desk(), w, { no_launch = true })
  check("--no-launch removes launch", without and #without == 0, ops_text(without))
end

-- A window pattern chooses among an app's windows.
do
  local w = base_world()
  table.insert(space(w, 1).windows, win(104, "com.microsoft.VSCode", "notes.md - Other", 0, 25, 1200, 800))
  local ops = P.plan(base_desk(), w, {})
  check("a window whose title misses the pattern is not taken", ops and #ops == 0, ops_text(ops))
end

-- An app that is running with no window for an entry is said, as unseen.
do
  local w = base_world()
  space(w, 2).windows[1].title = "notes.md - Other"
  local ops = P.plan(base_desk(), w, {})
  check("a running app with no matching window yields unseen, naming the entry",
    kinds(ops) == "unseen" and ops[1].path == "displays[0].spaces[1].apps[0]", ops_text(ops))
end

-- A space whose type could not be read is refused, not miscounted.
do
  local w = base_world()
  space(w, 2).type = nil
  space(w, 2).type_error = "spaceType failed"
  local ops, err = P.plan(base_desk(), w, {})
  check("a space with no type is refused, with the reason observe recorded",
    ops == nil and err ~= nil and string.find(err, "spaceType failed", 1, true) ~= nil, err)
end

-- A layout the validator should have refused is refused here too.
do
  local d = base_desk()
  d.displays[1].spaces[1].apps[1].layout = "left half"
  local ops, err = P.plan(d, base_world(), {})
  check("a malformed layout is refused naming its path, not raised",
    ops == nil and err ~= nil and string.find(err, "displays[0].spaces[0].apps[0].layout", 1, true) ~= nil, err)
end

-- Full screen is left alone (D11).
do
  local d = base_desk()
  d.displays[1].spaces[1].apps[1].layout = "fullscreen"
  local w = base_world()
  space(w, 1).windows[1].frame = { x = 1, y = 2, w = 3, h = 4 }
  local ops = P.plan(d, w, {})
  check("a fullscreen layout is left alone", ops and #ops == 0, ops_text(ops))
end

-- --bind: one bind per differing app, then one restart_dock.
do
  local w = base_world()
  w.app_bindings = { { bundle = "com.apple.mail", target = "SPACE-11" } }
  local ops = P.plan(base_desk(), w, { bind = true })
  local bound = {}
  for _, op in ipairs(ops or {}) do
    if op.op == "bind" then bound[op.bundle] = op.space end
  end
  check("--bind binds only the apps whose binding differs, then restarts the Dock once",
    kinds(ops) == "bind,bind,restart_dock" and bound["com.apple.Safari"] == "SPACE-11"
      and bound["com.microsoft.VSCode"] == "SPACE-12" and bound["com.apple.mail"] == nil, ops_text(ops))
  local none = P.plan(base_desk(), w, {})
  check("without --bind there is no bind", none and #none == 0, ops_text(none))
  local short = base_world()
  local vscode = table.remove(short.screens[1].spaces, 2).windows[1]
  table.insert(space(short, 1).windows, vscode)
  local planned = P.plan(base_desk(), short, { bind = true, no_create = true })
  local spaceless
  for _, op in ipairs(planned or {}) do
    if op.op == "bind" and op.bundle == "com.microsoft.VSCode" then spaceless = op end
  end
  check("--bind for a space that does not exist yet is kept, with no space and a reason",
    spaceless ~= nil and spaceless.space == nil and spaceless.reason ~= nil, ops_text(planned))
end

-- A malformed window pattern is refused naming its path, not raised.
do
  local d = base_desk()
  d.displays[1].spaces[2].apps[1].window = "Utilz ("
  local ops, err = P.plan(d, base_world(), {})
  check("a malformed window pattern is refused naming its path",
    ops == nil and err ~= nil and string.find(err, "displays[0].spaces[1].apps[0].window", 1, true) ~= nil, err)
end

-- A pattern that passes the early probes and fails only on a real title is
-- refused too, never raised.
do
  local d = base_desk()
  -- "%d(" passes both of bad_pattern's probes ("" and its own text, which
  -- holds no digit) and raises "unfinished capture" on a title with a digit:
  -- measured under LuaJIT. ("Utilz (%d+", the first candidate, never raises:
  -- the title's "(" is not a digit, so the match fails before the capture.)
  d.displays[1].spaces[2].apps[1].window = "%d("
  local w = base_world()
  space(w, 2).windows[1].title = "Utilz 1"
  local ok, ops, err = pcall(P.plan, d, w, {})
  check("a pattern that fails only on a real title is refused naming its path",
    ok and ops == nil and err ~= nil and string.find(err, "displays[0].spaces[1].apps[0].window", 1, true) ~= nil
      and string.find(err, 'on window title "Utilz 1"', 1, true) ~= nil,
    tostring(ok) .. " " .. tostring(err or ops))
end

-- A full-screen window is left alone even by a bare entry for its app (D11).
do
  local w = base_world()
  local mail = table.remove(space(w, 1).windows, 1)
  table.insert(w.screens[1].spaces, { id = 98, ordinal = 3, type = "fullscreen", windows = { mail } })
  local ops = P.plan(base_desk(), w, {})
  check("a window on a full-screen space is not claimed, so the entry is unseen",
    kinds(ops) == "unseen" and ops[1].bundle == "com.apple.mail", ops_text(ops))
end

-- A --map key that names no desk display is refused, not ignored.
do
  local ops, err = P.plan(base_desk(), base_world(), { map = { lfet = "SCREEN-A" } })
  check("--map with a key naming no desk display is refused, naming the displays",
    ops == nil and err ~= nil and string.find(err, "no display named lfet", 1, true) ~= nil
      and string.find(err, "left", 1, true) ~= nil, err)
end

-- Every op kind carries a reason: one world that produces all of them.
do
  local d = base_desk()
  table.insert(d.displays[1].spaces, { apps = { { app = "com.example.Absent", layout = "0,0 1x1" } } })
  d.displays[1].spaces[1].apps[2].window = "Nothing Like This"
  local w = base_world()
  local vscode = table.remove(space(w, 2).windows, 1)
  table.insert(space(w, 1).windows, vscode)
  space(w, 1).windows[1].frame = { x = 5, y = 30, w = 500, h = 500 }
  local ops = P.plan(d, w, { bind = true })
  local seen, missing = {}, {}
  for _, op in ipairs(ops or {}) do
    seen[op.op] = true
    if not op.reason then missing[#missing + 1] = op.op end
  end
  local all = seen.create_space and seen.launch and seen.move and seen.place and seen.unseen and seen.bind and seen.restart_dock
  check("one world yields every op kind", all, ops_text(ops))
  check("and every op of every kind carries a reason", #missing == 0, table.concat(missing, ","))
end

-- Display matching refuses rather than guesses.
do
  local d = base_desk()
  d.displays[1].match = { uuid = "NO-SUCH", name = "Other" }
  local ops, err = P.plan(d, base_world(), {})
  check("a desk display that matches no screen is refused, naming the candidates",
    ops == nil and err ~= nil and string.find(err, "SCREEN-A", 1, true) ~= nil, err)
  local mapped = P.plan(d, base_world(), { map = { left = "SCREEN-A" } })
  check("--map binds the display to a screen by uuid", mapped and #mapped == 0, ops_text(mapped))
  local unknown, why = P.plan(d, base_world(), { map = { left = "NO-SUCH" } })
  check("--map naming no screen is refused, naming the screens there are",
    unknown == nil and why ~= nil and string.find(why, "SCREEN-A", 1, true) ~= nil, why)
end

-- Matching by name and size, where the size comes from a fractional frame.
do
  local d = base_desk()
  d.displays[1].match = { name = "VY229HF", size = "1200x825" }
  local w = base_world()
  w.screens[1].full_frame.w = 1199.6
  local ops, err = P.plan(d, w, {})
  check("a display matches by name and size, the size rounded from a fractional frame",
    ops and #ops == 0, err or ops_text(ops))
end

-- Two identical panels are told apart by position, and two desk displays on
-- one screen are refused.
do
  local w = base_world()
  local twin = {
    uuid = "SCREEN-B", name = "VY229HF", primary = false, position = "above-left",
    frame = { x = -1200, y = -800, w = 1200, h = 800 }, full_frame = { x = -1200, y = -825, w = 1200, h = 825 },
    spaces = { { id = 21, ordinal = 1, type = "user", uuid = "SPACE-21", windows = {} } },
  }
  table.insert(w.screens, twin)
  local d = base_desk()
  d.displays[1].match = { name = "VY229HF", size = "1200x825", position = "main" }
  local ops, err = P.plan(d, w, {})
  check("two identical panels resolve by position", ops and #ops == 0, err or ops_text(ops))
  d.displays[1].match.position = nil
  local none, why = P.plan(d, w, {})
  check("two identical panels with no position refuse, listing both",
    none == nil and why ~= nil and string.find(why, "SCREEN-A", 1, true) ~= nil
      and string.find(why, "SCREEN-B", 1, true) ~= nil, why)
  local two = base_desk()
  table.insert(two.displays, { name = "again", match = { uuid = "SCREEN-A" }, spaces = {} })
  local dup, dwhy = P.plan(two, base_world(), {})
  check("two desk displays matching one screen are refused",
    dup == nil and dwhy ~= nil and string.find(dwhy, "both match screen SCREEN-A", 1, true) ~= nil, dwhy)
end

-- The observe report counts desktops with the planner's own predicate.
do
  local w = base_world()
  w.separate_spaces, w.accessibility, w.stage_manager = true, true, false
  table.insert(w.screens[1].spaces, { id = 99, ordinal = 3, type = "fullscreen", window_ids = 1, named = 1, windows = {} })
  space(w, 1).window_ids, space(w, 1).named = 4, 2
  local lines = P.observe_report(w)
  check("the observe report counts every space and only the desktops as desktops",
    lines[1] == "main VY229HF (SCREEN-A): 3 spaces, 2 desktop; 5 windows, 3 named", lines[1])
  check("and ends with the settings and the binding count",
    lines[2] == "separate spaces true, accessibility true, stage manager false, 0 Dock bindings", lines[2])
end

print(string.format("plan_test: %d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
