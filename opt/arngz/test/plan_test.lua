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

local here = (plan_path:match("^(.*)/lib/plan%.lua$") or "opt/arngz") .. "/test/fixtures/worlds.lua"
local F = dofile(arg[2] or here)
local base_desk, base_world, win = F.base_desk, F.base_world, F.win

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
  check("and the target space's id, and where the window is now",
    ops and ops[1].space == 12 and ops[1].from_space == 11 and ops[1].from_screen == "SCREEN-A")
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
  check("and its move carries no space id, because that space does not exist yet",
    ops and ops[2] and ops[2].space == nil and ops[2].ordinal == 2, ops_text(ops))
  local without = P.plan(base_desk(), w, { no_create = true })
  check("--no-create removes create_space, and says the window has no space to go to, neither moved nor placed",
    kinds(without) == "no_space" and without[1].window == 103 and string.find(without[1].reason, "does not exist", 1, true) ~= nil,
    ops_text(without))
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
  check("--no-launch launches nothing and says so, as not_launched with a reason and the entry's path",
    kinds(without) == "not_launched" and without[1].bundle == "com.apple.Safari" and without[1].reason ~= nil
      and without[1].path == "displays[0].spaces[0].apps[1]", ops_text(without))
  local again = P.plan(base_desk(), w, { launched = { ["com.apple.safari"] = false } })
  check("an app whose launch this apply tried and did not finish is not launched again, and left to that result",
    again and #again == 0, ops_text(again))
  local quit = P.plan(base_desk(), w, { launched = { ["com.apple.safari"] = true } })
  check("an app this apply launched that is not running now is gone, never placed, and not launched again",
    kinds(quit) == "gone" and quit[1].path == "displays[0].spaces[0].apps[1]" and quit[1].reason ~= nil, ops_text(quit))
  local before = P.plan(base_desk(), w, { running_before = { ["com.apple.safari"] = true } })
  check("a second plan reports an app that quit since apply began as gone, and launches nothing",
    kinds(before) == "gone" and string.find(before[1].reason, "was running when apply began", 1, true) ~= nil, ops_text(before))
  local never = P.plan(base_desk(), w, { running_before = {} })
  check("and one that was not running then is left to its launch's result", never and #never == 0, ops_text(never))
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

-- A screen whose spaces, or a space whose windows, could not be read is
-- refused too: read as empty, it would plan create_space for spaces that
-- exist, and unseen or moves for windows that are there.
do
  local w = base_world()
  w.screens[1].spaces_error = "spacesForScreen failed"
  w.screens[1].spaces = {}
  local ops, err = P.plan(base_desk(), w, {})
  check("plan refuses a screen whose spaces could not be read, and plans no create_space",
    ops == nil and string.find(tostring(err), "spacesForScreen failed", 1, true) ~= nil, err or ops_text(ops))
  local v = base_world()
  space(v, 2).windows_error = "windowsForSpace failed"
  space(v, 2).windows = {}
  ops, err = P.plan(base_desk(), v, {})
  check("plan refuses a space whose windows could not be read, and plans no unseen",
    ops == nil and string.find(tostring(err), "windowsForSpace failed", 1, true) ~= nil, err or ops_text(ops))
  -- On a screen the desk does not match too: plan's window pool is the world's.
  local u = base_world()
  table.insert(u.screens, {
    uuid = "SCREEN-B", name = "Other", primary = false, position = "above",
    frame = { x = 0, y = -800, w = 1200, h = 800 }, full_frame = { x = 0, y = -825, w = 1200, h = 825 },
    spaces = { { id = 21, ordinal = 1, type = "user", uuid = "SPACE-21", windows = {},
      windows_error = "windowsForSpace failed" } },
  })
  ops, err = P.plan(base_desk(), u, {})
  check("plan refuses an unread space on a screen the desk does not match",
    ops == nil and string.find(tostring(err), "windowsForSpace failed", 1, true) ~= nil, err or ops_text(ops))
end

-- Dock bindings that could not be read do not stop a plan: there is no --bind
-- in v1 (D10, AC-05.6), so plan never reads them.
do
  local w = base_world()
  w.prefs_errors = { spaces = "defaults export failed" }
  w.bindings_error = "app-bindings is a string, not a table of bindings"
  local ops, err = P.plan(base_desk(), w, {})
  check("a plan goes ahead when the Dock bindings could not be read", ops ~= nil and #ops == 0, err or ops_text(ops))
  ops = P.plan(base_desk(), base_world(), { bind = true })
  check("and an option named bind plans no bind and no Dock restart", ops ~= nil and #ops == 0, ops_text(ops))
end

-- Windows that could not be listed at all are refused; one window that went
-- away between being listed and being read is only not seen.
do
  local w = base_world()
  w.windows_list_error = "hs.window.allWindows failed four times: axuielement"
  local ops, err = P.plan(base_desk(), w, {})
  check("plan refuses a world whose windows could not be listed", ops == nil
    and string.find(tostring(err), "could not be listed", 1, true) ~= nil, err or ops_text(ops))
  local v = base_world()
  space(v, 1).windows[2] = { id = 102, named = false, read_error = "incorrect type 'nil'" }
  local vops, verr = P.plan(base_desk(), v, {})
  check("plan does not refuse on a window record carrying read_error, and its unseen reason says so",
    kinds(vops) == "unseen" and vops[1].bundle == "com.apple.Safari"
      and string.find(vops[1].reason, "1 window(s) could not be read just now (incorrect type 'nil')", 1, true) ~= nil,
    verr or ops_text(vops))
  local u = base_world()
  table.remove(space(u, 1).windows, 2)
  u.window_id_errors, u.window_id_error = 2, "axuielement gone"
  u.window_filter = "failed: no filter"
  local uops, uerr = P.plan(base_desk(), u, {})
  check("an unseen reason counts the window id reads that failed, and names a window filter that failed",
    kinds(uops) == "unseen"
      and string.find(uops[1].reason, "2 window id read(s) failed (axuielement gone)", 1, true) ~= nil
      and string.find(uops[1].reason, "names windows on other spaces failed: no filter", 1, true) ~= nil,
    uerr or ops_text(uops))
end

-- After launching, apply waits until each launched app has a claimable
-- window named on a space.
do
  local w = base_world()
  local none = P.unsettled_launches(w, { ["com.apple.safari"] = true, ["com.example.never"] = false })
  check("an app whose launch was done and whose window is named is not waited on; one not done is not either",
    #none == 0, table.concat(none, ","))
  local unnamed = base_world()
  space(unnamed, 1).windows[2].named = false
  local wait = P.unsettled_launches(unnamed, { ["com.apple.safari"] = true })
  check("an app whose launch was done with no named window is waited on", wait[1] == "com.apple.safari",
    table.concat(wait, ","))
  local unlisted = base_world()
  unlisted.apps_running = { "com.apple.mail", "com.microsoft.VSCode" }
  local wait2 = P.unsettled_launches(unlisted, { ["com.apple.safari"] = true })
  check("and so is one with a named window that is not yet listed as running", wait2[1] == "com.apple.safari",
    table.concat(wait2, ","))
  local fs = base_world()
  local safari = table.remove(space(fs, 1).windows, 2)
  table.insert(fs.screens[1].spaces, { id = 98, ordinal = 3, type = "fullscreen", windows = { safari } })
  local wait3 = P.unsettled_launches(fs, { ["com.apple.safari"] = true })
  check("a launched app whose only window is on a full-screen space is still waited on, as plan cannot claim it",
    wait3[1] == "com.apple.safari", table.concat(wait3, ","))
  local noapps = base_world()
  noapps.apps_running_error = "hs.application.runningApplications: axuielement"
  local nops, nerr = P.plan(base_desk(), noapps, {})
  check("plan refuses a world whose running apps could not be listed, never launching what runs",
    nops == nil and string.find(tostring(nerr), "running apps could not be listed", 1, true) ~= nil, nerr or ops_text(nops))
end

-- A screen whose space order could not be read (D22) is refused, never
-- ordered by guess.
do
  local w = base_world()
  w.screens[1].order_error = "no list in com.apple.spaces holds exactly this screen's spaces"
  local ops, err = P.plan(base_desk(), w, {})
  check("plan refuses a screen whose space order could not be read",
    ops == nil and string.find(tostring(err), "order of screen SCREEN-A", 1, true) ~= nil, err or ops_text(ops))
end

-- One app named in two cases in a desk is launched once.
do
  local w = base_world()
  w.apps_running = {}
  local d = base_desk()
  d.displays[1].spaces[2].apps[1].app = "com.Apple.Mail"
  d.displays[1].spaces[2].apps[1].window = "^nothing$"
  table.insert(d.displays[1].spaces[1].apps, { app = "com.apple.mail", window = "^nothing either$", layout = "0,0 1x1" })
  local ops = P.plan(d, w, {})
  local mail = 0
  for _, op in ipairs(ops or {}) do
    if op.op == "launch" and string.lower(op.bundle) == "com.apple.mail" then mail = mail + 1 end
  end
  check("an app a desk names in two cases is launched once", mail == 1, ops_text(ops))
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
  local ops = P.plan(d, w, {})
  local seen, missing = {}, {}
  for _, op in ipairs(ops or {}) do
    seen[op.op] = true
    if not op.reason then missing[#missing + 1] = op.op end
  end
  local all = seen.create_space and seen.launch and seen.move and seen.place and seen.unseen
  check("one world yields every op kind it can", all, ops_text(ops))
  -- The kinds one world cannot yield beside those: each from its own world.
  local more = {}
  local nl = base_world()
  nl.apps_running = { "com.apple.mail", "com.microsoft.VSCode" }
  table.remove(space(nl, 1).windows, 2)
  for _, op in ipairs(P.plan(base_desk(), nl, { no_launch = true }) or {}) do more[#more + 1] = op end
  for _, op in ipairs(P.plan(base_desk(), nl, { launched = { ["com.apple.safari"] = true } }) or {}) do more[#more + 1] = op end
  local short = base_world()
  table.insert(space(short, 1).windows, table.remove(short.screens[1].spaces, 2).windows[1])
  for _, op in ipairs(P.plan(base_desk(), short, { no_create = true }) or {}) do more[#more + 1] = op end
  local sticky3 = base_world()
  table.insert(space(sticky3, 1).windows, space(sticky3, 2).windows[1])
  table.insert(sticky3.screens[1].spaces, { id = 13, ordinal = 3, type = "user", uuid = "SPACE-13", windows = {} })
  local d3 = base_desk()
  table.insert(d3.displays[1].spaces, { apps = { { app = "com.microsoft.VSCode", window = "Utilz", layout = "0,0 12x8" } } })
  table.remove(d3.displays[1].spaces[2].apps, 1)
  for _, op in ipairs(P.plan(d3, sticky3, {}) or {}) do more[#more + 1] = op end
  local sticky2 = base_world()
  table.insert(space(sticky2, 1).windows, space(sticky2, 2).windows[1])
  for _, op in ipairs(P.plan(d3, sticky2, {}) or {}) do more[#more + 1] = op end
  for _, op in ipairs(more) do
    seen[op.op] = true
    if not op.reason then missing[#missing + 1] = op.op end
  end
  local every = { "create_space", "launch", "move", "place", "unseen", "not_launched", "gone", "unmovable", "no_space",
    "pending" }
  local absent = {}
  for _, k in ipairs(every) do
    if not seen[k] then absent[#absent + 1] = k end
  end
  check("between them, the worlds yield all ten op kinds", #absent == 0, table.concat(absent, ","))
  check("and every op of every kind carries a reason", #missing == 0, table.concat(missing, ","))
  local all_ops = {}
  for _, op in ipairs(ops or {}) do all_ops[#all_ops + 1] = op end
  for _, op in ipairs(more) do all_ops[#all_ops + 1] = op end
  local described = P.plan_report(all_ops)
  local raw = 0
  for _, line in ipairs(described) do
    if string.find(line, "^[a-z_]+ %(") then raw = raw + 1 end
  end
  check("and plan_report describes every kind in words, never by its bare name", raw == 0, table.concat(described, " | "))
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

-- ------------------------------------------------------------- space order (D22)

print("space order")
do
  -- hv's plist, measured 16 Oct 2026: the built-in is "Main", detached
  -- displays keep empty lists, and Mission Control's order is the plist's.
  local monitors = {
    { ["Display Identifier"] = "Main", Spaces = {
      { ManagedSpaceID = 1 }, { ManagedSpaceID = 3 }, { ManagedSpaceID = 2588 }, { ManagedSpaceID = 1733 },
      { ManagedSpaceID = 305 } } },
    { ["Display Identifier"] = "34791BF3", Spaces = { { ManagedSpaceID = 2634 } } },
    { ["Display Identifier"] = "6F89E131" },
  }
  local order = P.order_spaces({ 1, 3, 2588, 305, 1733 }, monitors)
  check("a screen's spaces take the plist's order, not the live list's",
    order and table.concat(order, ",") == "1,3,2588,1733,305", order and table.concat(order, ","))
  local one = P.order_spaces({ 2634 }, monitors)
  check("a screen's list is the one holding exactly its spaces, wherever it sits", one and one[1] == 2634)
  local missing, why = P.order_spaces({ 1, 3, 2588, 305, 1733, 4000 }, monitors)
  check("a screen with a space the plist does not list yet has no order, and says why",
    missing == nil and string.find(tostring(why), "4000", 1, true) ~= nil, why)
  local fewer = P.order_spaces({ 1, 3 }, monitors)
  check("a list holding more than the screen's spaces is not its list", fewer == nil)
  local twice, why2 = P.order_spaces({ 2634 }, { monitors[2], monitors[2] })
  check("two lists that both fit refuse rather than choose", twice == nil and why2 ~= nil, why2)
end

-- ------------------------------------------------------------- moving (D21)

print("moving")
do
  -- hv's machine: two panels above a laptop, sharing parts of its top edge.
  local laptop = { uuid = "L", full = { x = 0, y = 0, w = 1800, h = 1169 }, frame = { x = 0, y = 25, w = 1800, h = 1144 } }
  local left = { uuid = "B", full = { x = -1021, y = -1080, w = 1920, h = 1080 }, frame = { x = -1021, y = -1080, w = 1920, h = 1055 } }
  local right = { uuid = "A", full = { x = 899, y = -1080, w = 1920, h = 1080 }, frame = { x = 899, y = -1080, w = 1920, h = 1055 } }
  local far = { uuid = "F", full = { x = 5000, y = 0, w = 1000, h = 800 }, frame = { x = 5000, y = 0, w = 1000, h = 800 } }
  local screens = { laptop, left, right, far }

  local e = P.touching(laptop.full, left.full)
  check("two displays sharing part of an edge touch along the shared part",
    e and e.axis == "y" and e.at == 0 and e.dir == -1 and e.lo == 0 and e.hi == 899, e and (e.lo .. ".." .. e.hi))
  check("displays meeting only at a corner do not touch",
    P.touching({ x = 0, y = 0, w = 100, h = 100 }, { x = 100, y = 100, w = 100, h = 100 }) == nil)
  local a, b = P.crossing(e, { x = 1500, y = 300 })
  check("a crossing keeps the margin from the ends of the shared edge, 3 px either side",
    a.x == 899 - P.MARGIN_PX and a.y == 3 and b.y == -3, a.x .. "," .. a.y .. " " .. b.x .. "," .. b.y)
  local chain = P.route(screens, "B", "A")
  check("a route takes the fewest crossings: left panel to right panel through the laptop is not needed",
    chain and #chain == 2 and chain[2].uuid == "A", chain and #chain)
  check("no chain of shared edges is no route", P.route(screens, "L", "F") == nil)
  local up = P.route(screens, "L", "B")
  local pts = P.path(up, { x = 500, y = 40 }, { x = -500, y = -900 })
  check("a path crosses each shared edge and ends at the drop point",
    #pts == 3 and pts[1].y == 3 and pts[2].y == -3 and pts[3].x == -500, #pts)
  local drop = P.drop_point({ x = 120, y = 40 }, { x = 100, y = 25, w = 600, h = 400 }, left)
  check("the drop point puts the window's top left 80 points into the target's visible frame",
    drop.x == -1021 + 80 + 20 and drop.y == -1080 + 80 + 15, drop.x .. "," .. drop.y)

  local g = P.grab_candidates({ x = 100, y = 25, w = 600, h = 400 }, { x = 150, y = 31, w = 14, h = 16 })
  check("the first grab point is just right of the zoom button on the bar's centre line",
    g[1].x == 180 and g[1].y == 39 and #g == 6, g[1].x .. "," .. g[1].y .. " of " .. #g)
  local narrow = P.grab_candidates({ x = 0, y = 0, w = 40, h = 300 }, nil)
  check("points off the bar are dropped, and with no zoom button the line is 12 points down",
    #narrow == 4 and narrow[1].y == 12, #narrow)

  local mods = P.decode_mods(0x40000 + 0x800000)
  check("a symbolic hotkey's mask decodes to its modifiers, fn kept",
    table.concat(mods, ",") == "ctrl,fn", table.concat(mods, ","))
  local prefs = { AppleSymbolicHotKeys = {
    ["79"] = { enabled = true, value = { parameters = { 65535, 123, 8650752 } } },
    ["81"] = { enabled = 0, value = { parameters = { 65535, 124, 8650752 } } },
  } }
  local k = P.hotkey(prefs, 79)
  check("Move left a space reads as its keycode and modifiers",
    k and k.keycode == 123 and table.concat(k.mods, ",") == "ctrl,fn")
  local off, why_off = P.hotkey(prefs, 81)
  check("a shortcut turned off is refused, named", off == nil and string.find(why_off, "turned off", 1, true) ~= nil)
  local unset, why_unset = P.hotkey({ AppleSymbolicHotKeys = {} }, 79)
  check("an unset shortcut is refused, because macOS's default cannot be read",
    unset == nil and string.find(why_unset, "not set", 1, true) ~= nil)
  check("unreadable preferences are refused", P.hotkey(nil, 79) == nil)

  local steps, side = P.walk({ 1, 3, 2588, 1733 }, 3, 1733)
  check("a walk lists the spaces passed, first step first, and its side",
    table.concat(steps, ",") == "2588,1733" and side == "right")
  local back, bside = P.walk({ 1, 3, 2588, 1733 }, 1733, 1)
  check("and walks left", table.concat(back, ",") == "2588,3,1" and bside == "left")
  check("a walk to where it is has no steps", #P.walk({ 1, 3 }, 3, 3) == 0)
  check("a walk from a space not in the order is nil", P.walk({ 1, 3 }, 9, 3) == nil)

  local now = {
    order = { L = { 1, 3, 50, 2588 }, A = { 7, 8 } },
    types = { [1] = "user", [3] = "user", [50] = "fullscreen", [2588] = "user", [7] = "user", [8] = "user" },
    active = { L = 1, A = 7 },
  }
  local legs = P.move_legs(now, { screen = "L", space = 3, from_screen = "L", from_space = 1 })
  check("within a display, on the space shown: one carry of one step",
    legs and #legs == 1 and legs[1].kind == "carry" and table.concat(legs[1].steps, ",") == "3" and legs[1].side == "right")
  legs = P.move_legs(now, { screen = "L", space = 1, from_screen = "L", from_space = 3 })
  check("within a display, off the space shown: switch to the window's space, then carry",
    legs and #legs == 2 and legs[1].kind == "switch" and legs[1].steps[1] == 3 and legs[2].kind == "carry"
      and legs[2].side == "left")
  local none, why = P.move_legs(now, { screen = "L", space = 2588, from_screen = "L", from_space = 3 })
  check("a held carry across a full-screen space is refused, named", none == nil and string.find(why, "fullscreen", 1, true) ~= nil, why)
  legs = P.move_legs(now, { screen = "A", space = 8, from_screen = "L", from_space = 3 })
  check("across displays: the target shows the target space, the origin shows the window, then the drag",
    legs and #legs == 3 and legs[1].kind == "switch" and legs[1].screen == "A" and legs[1].steps[1] == 8
      and legs[2].kind == "switch" and legs[2].screen == "L" and legs[3].kind == "drag" and legs[3].space == 8)
  legs = P.move_legs(now, { screen = "A", space = 7, from_screen = "L", from_space = 1 })
  check("across displays, both already showing: the drag alone", legs and #legs == 1 and legs[1].kind == "drag")
  local gone, gwhy = P.move_legs(now, { screen = "L", space = nil, ordinal = 5, from_screen = "L", from_space = 1 })
  check("a move to a space that does not exist is refused, naming the ordinal",
    gone == nil and string.find(gwhy, "space 5", 1, true) ~= nil, gwhy)
  legs = P.move_legs(now, { screen = "L", space = 1, from_screen = "L", from_space = 1 })
  check("a window already there has no legs", legs and #legs == 0)
  local blind = { order = now.order, types = now.types, active = { A = 7 }, active_error = { L = "activeSpaceOnScreen failed" } }
  local nolegs, bwhy = P.move_legs(blind, { screen = "L", space = 3, from_screen = "L", from_space = 1 })
  check("a display whose shown space could not be read refuses the move with the read's error",
    nolegs == nil and string.find(bwhy, "activeSpaceOnScreen failed", 1, true) ~= nil, bwhy)

  local op = { screen = "L", space = 3 }
  local good = { window_spaces = { 3 }, shown = 3, listed_at_destination = true, listed_at_origin = false, origin = 1 }
  check("a readback that agrees is done", P.move_verdict(good, op, true) == "done")
  local function with(k, v)
    local t = {}
    for key, val in pairs(good) do t[key] = val end
    t[k] = v
    return t
  end
  check("still on its origin too is failed", P.move_verdict(with("listed_at_origin", true), op, true) == "failed")
  check("on two spaces is failed", P.move_verdict(with("window_spaces", { 1, 3 }), op, true) == "failed")
  check("the display not showing the target is failed", P.move_verdict(with("shown", 1), op, true) == "failed")
  check("not listed at the destination is failed", P.move_verdict(with("listed_at_destination", false), op, true) == "failed")
  local st, rwhy = P.move_verdict(with("errors", { "windowsForSpace(3): failed" }), op, true)
  check("a readback that could not be read is failed with what could not be read, never read as not listed",
    st == "failed" and string.find(rwhy, "windowsForSpace(3): failed", 1, true) ~= nil, rwhy)
  check("a window with no legs, already on its space, is done whatever the display shows",
    P.move_verdict(with("shown", 1), op, false) == "done")
  check("and one with no legs that is elsewhere is failed", P.move_verdict(with("window_spaces", { 1 }), op, false) == "failed")

  local w = base_world()
  local in_place, perr = P.plan(base_desk(), w, {})
  check("a world in place needs no hand", in_place and #in_place == 0 and P.needs_hand(in_place, w) == false, perr)
  local hiddenw = base_world()
  space(hiddenw, 2).windows[1].frame = { x = 5, y = 30, w = 500, h = 500 }
  local hidden_ops, herr = P.plan(base_desk(), hiddenw, {})
  check("a place for a window on a desktop not shown needs the hand",
    kinds(hidden_ops) == "place" and P.needs_hand(hidden_ops, hiddenw) == true, herr or ops_text(hidden_ops))
  local shownw = base_world()
  space(shownw, 1).windows[1].frame = { x = 5, y = 30, w = 500, h = 500 }
  local shown_ops, serr = P.plan(base_desk(), shownw, {})
  check("a place for a window on the shown desktop does not",
    kinds(shown_ops) == "place" and P.needs_hand(shown_ops, shownw) == false, serr or ops_text(shown_ops))
  local sticky = base_world()
  local vs = space(sticky, 2).windows[1]
  vs.frame = { x = 5, y = 30, w = 500, h = 500 }
  table.insert(space(sticky, 1).windows, vs)
  check("a window on every space, the shown one included, is not hidden",
    P.needs_hand({ { op = "place", window = 103 } }, sticky) == false)
  -- The mirror: the shown listing second, so "any listing shown" is what passes.
  local mirror = base_world()
  local mv = space(mirror, 2).windows[1]
  table.insert(space(mirror, 1).windows, mv)
  space(mirror, 1).active = false
  space(mirror, 2).active = true
  check("and so is one whose shown listing is the second",
    P.needs_hand({ { op = "place", window = 103 } }, mirror) == false)
end

-- A window on every space is in place on any of them: plan moves it nowhere,
-- whichever listing claims it first.
do
  local w = base_world()
  local vs = space(w, 2).windows[1]
  table.insert(space(w, 1).windows, 1, vs)
  local ops, err = P.plan(base_desk(), w, {})
  check("a window on every space, its target the second listing, is not moved", ops and #ops == 0, err or ops_text(ops))
  local l = P.listings(w)
  check("listings: one window on two spaces, one of them shown",
    l[103].count == 2 and l[103].spaces[11] and l[103].spaces[12] and l[103].shown == true)
  -- On two spaces, and wanted on a third that exists: no gesture carries it,
  -- so plan says so and plans nothing for it.
  local far = base_world()
  local fv = space(far, 2).windows[1]
  table.insert(space(far, 1).windows, fv)
  table.insert(far.screens[1].spaces, { id = 13, ordinal = 3, type = "user", uuid = "SPACE-13", windows = {} })
  local d = base_desk()
  table.insert(d.displays[1].spaces, { apps = { { app = "com.microsoft.VSCode", window = "Utilz", layout = "0,0 12x8" } } })
  table.remove(d.displays[1].spaces[2].apps, 1)
  local uops, uerr = P.plan(d, far, {})
  check("a window on every space wanted on a space it is not on is unmovable, said, and neither moved nor placed",
    kinds(uops) == "unmovable" and uops[1].window == 103 and string.find(uops[1].reason, "on 2 spaces", 1, true) ~= nil,
    uerr or ops_text(uops))
  -- Wanted on a space still to be created: the plan after creating it
  -- decides, so nothing is predicted for the window now.
  local soon = base_world()
  table.insert(space(soon, 1).windows, space(soon, 2).windows[1])
  local cops, cerr = P.plan(d, soon, {})
  check("a window on every space wanted on a space to be created waits for the plan after it, said, with no failure predicted",
    kinds(cops) == "create_space,pending" and cops[2].window == 103, cerr or ops_text(cops))
  -- The second plan after that creation failed: never a silent "placed".
  local after, aerr = P.plan(d, soon, { no_create = true, after_create = true })
  check("after a creation that failed, that window has no space, and the reason names the failed creation",
    kinds(after) == "no_space" and after[1].window == 103 and string.find(after[1].reason, "creating it failed", 1, true) ~= nil,
    aerr or ops_text(after))
  local gone_space = P.plan(d, soon, { no_create = true, user_no_create = false })
  check("in a second plan that created nothing, a missing space is one gone since apply began, never --no-create",
    kinds(gone_space) == "no_space" and string.find(gone_space[1].reason, "gone since apply began", 1, true) ~= nil,
    ops_text(gone_space))
end

print("launch")
do
  check("open -b that ran is no verdict", P.launch_verdict(true, "", 0) == nil)
  local st, why = P.launch_verdict(false, "Unable to find application named\nLSCopy: determine the application with bundle identifier com.x\n", 1)
  check("a bundle id nothing carries is skipped, as not installed", st == "skipped" and string.find(why, "^not installed") ~= nil, why)
  local fst, fwhy = P.launch_verdict(false, "The application cannot be opened\n", 1)
  check("any other failure is failed, with open's words and exit", fst == "failed" and string.find(fwhy, "exited 1", 1, true) ~= nil, fwhy)
end

-- ------------------------------------------------------------- the report

print("report")
do
  local d = base_desk()
  local function r(op, path, status, reason, bundle) return { op = op, path = path, status = status, reason = reason, bundle = bundle } end
  local lines, code = P.apply_report(d, {})
  check("every entry placed exits 0, one line per entry", code == 0 and #lines == 3 and string.find(lines[1], ": placed$") ~= nil,
    table.concat(lines, " | "))
  lines, code = P.apply_report(d, {
    r("move", "displays[0].spaces[1].apps[0]", "done"), r("place", "displays[0].spaces[1].apps[0]", "done"),
  })
  check("a done move reads as moved and placed", code == 0 and string.find(lines[3], "moved and placed", 1, true) ~= nil, lines[3])
  lines, code = P.apply_report(d, { r("launch", "displays[0].spaces[0].apps[1]", "done", nil, "com.apple.Safari") })
  check("a done launch reads as launched and placed", code == 0 and string.find(lines[2], "launched and placed", 1, true) ~= nil, lines[2])
  lines, code = P.apply_report(d, { r("launch", "displays[0].spaces[0].apps[1]", "skipped", "not installed", "com.apple.Safari") })
  check("an app not installed is skipped, exit 1", code == 1 and string.find(lines[2], "skipped: not installed", 1, true) ~= nil, lines[2])
  lines, code = P.apply_report(d, { r("unseen", "displays[0].spaces[0].apps[0]", "unseen", "no window") })
  check("an entry no window matched is unseen, exit 1", code == 1 and string.find(lines[1], "unseen: no window", 1, true) ~= nil, lines[1])
  lines, code = P.apply_report(d, {
    r("move", "displays[0].spaces[1].apps[0]", "failed", "the readback shows it on space 11"),
    r("place", "displays[0].spaces[1].apps[0]", "failed", "its move failed"),
  })
  check("a move whose readback disagreed is failed, with why, exit 1",
    code == 1 and string.find(lines[3], "failed: the readback shows it on space 11", 1, true) ~= nil, lines[3])
  lines, code = P.apply_report(d, { r("not_launched", "displays[0].spaces[0].apps[1]", "skipped", "--no-launch") })
  check("an app left unlaunched by --no-launch is skipped, exit 1", code == 1 and string.find(lines[2], "skipped", 1, true) ~= nil, lines[2])
  lines, code = P.apply_report(d, { r("plan", nil, "failed", "the plan after creating and launching refused: x") })
  local any_placed = false
  for _, l in ipairs(lines) do
    if string.find(l, ": placed", 1, true) or string.find(l, "and placed", 1, true) then any_placed = true end
  end
  check("when the engine could not go on, no entry reads as placed, and the exit is 1",
    code == 1 and not any_placed and string.find(lines[1], "not finished: the plan after", 1, true) ~= nil, lines[1])
  for _, what in ipairs({ "observe", "execute" }) do
    lines, code = P.apply_report(d, { r(what, nil, "failed", "boom") })
    check("a failed " .. what .. " after things changed leaves no entry placed",
      code == 1 and string.find(lines[1], "failed: not finished: boom", 1, true) ~= nil, lines[1])
  end
  lines, code = P.apply_report(d, { r("gone", "displays[0].spaces[0].apps[1]", "failed", "quit"),
    r("launch", "displays[0].spaces[0].apps[1]", "done", nil, "com.apple.Safari") })
  check("a launched app that quit reads as failed, not launched and placed",
    code == 1 and string.find(lines[2], "failed: quit", 1, true) ~= nil, lines[2])
  lines, code = P.apply_report(d, { r("restore", nil, "note", "focus left where it is") })
  check("a note is said and leaves the exit at 0, with no path printed for it",
    code == 0 and #lines == 4 and lines[4] == "restore: note: focus left where it is", lines[4])
  lines, code = P.apply_report(d, { r("create_space", "displays[0].spaces[2]", "failed", "addSpaceToScreen returned false") })
  check("a failed op that serves no one entry is its own line, and lifts the exit",
    code == 1 and #lines == 4 and string.find(lines[4], "create_space", 1, true) ~= nil, lines[4])
end

-- ------------------------------------------------------------- discover

print("discover")

-- A deep, ordered rendering of a value, so two desks compare as text.
local function render(v, indent)
  indent = indent or ""
  if type(v) ~= "table" then return string.format("%q", tostring(v)) end
  local keys = {}
  for k in pairs(v) do keys[#keys + 1] = k end
  table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
  local parts = {}
  for _, k in ipairs(keys) do parts[#parts + 1] = indent .. tostring(k) .. "=" .. render(v[k], indent .. " ") end
  return "{\n" .. table.concat(parts, "\n") .. "}"
end

-- Only placing ops: the discovered desk claims exactly the windows it recorded.
local function only_places(desk, world)
  local ops, err = P.plan(desk, world, {})
  if not ops then return false, err end
  local stray = {}
  for _, op in ipairs(ops) do
    if op.op ~= "place" then stray[#stray + 1] = op.op .. "(" .. tostring(op.window or op.bundle) .. ")" end
  end
  return #stray == 0, table.concat(stray, ",")
end

local function notes_text(notes) return table.concat(notes or {}, " | ") end
local function has_note(notes, text)
  for _, n in ipairs(notes or {}) do
    if string.find(n, text, 1, true) then return true end
  end
  return false
end

do
  local desk = P.desk_from_world(base_world(), { grid = "12x8", name = "base" })
  local ops, err = P.plan(desk, base_world(), {})
  check("a desk discovered from a world plans nothing against that world", ops and #ops == 0, err or ops_text(ops))
  local again = P.desk_from_world(base_world(), { grid = "12x8", name = "base" })
  check("discovering the same world twice gives the same desk", render(desk) == render(again))
  check("the default grid is 8x4", P.desk_from_world(base_world(), {}).grid == "8x4")
end

do
  local world = F.discover_world()
  local desk, notes = P.desk_from_world(world, { name = "zeop2" })
  local d1, d2, d3 = desk.displays[1], desk.displays[2], desk.displays[3]
  check("the primary is first and each display is named by its position",
    d1.name == "main" and d2.name == "above-left" and d3.name == "above-right",
    tostring(d1.name) .. "," .. tostring(d2.name) .. "," .. tostring(d3.name))
  check("each display is recorded with all four match fields, the panel name without its (n)",
    d2.match.uuid == "SCREEN-B" and d2.match.name == "VY229HF" and d2.match.size == "1920x1080"
      and d2.match.position == "above-left")
  local s1 = d1.spaces[1].apps
  local by_app = {}
  for _, a in ipairs(s1) do by_app[(a.window or a.app)] = a end
  check("a window exactly on its cells has no misfit", by_app["com.apple.mail"] and by_app["com.apple.mail"].misfit == nil)
  local docs
  for _, a in ipairs(s1) do if a.window and string.find(a.window, "Docs", 1, true) then docs = a end end
  check("a window 3 px off is recorded at its cell with misfit 3px",
    docs and docs.layout == "4,0 4x4" and docs.misfit == "3px", docs and (docs.layout .. " " .. tostring(docs.misfit)))
  check("the same app twice on a display carries a window pattern on each, its magic escaped",
    docs and docs.window == "^Docs %(draft%) 100%%$", docs and docs.window)
  local members = {}
  for _, a in ipairs(s1) do members[#members + 1] = a.app .. "|" .. tostring(a.window) .. "|" .. a.layout end
  table.sort(members)
  check("the first desktop holds mail bare, both Safari windows by pattern, and the full-screen TV filed after it",
    table.concat(members, " ") == "com.apple.Safari|^Docs %(draft%) 100%%$|4,0 4x4 com.apple.Safari|^News$|4,0 4x4"
      .. " com.apple.TV|nil|fullscreen com.apple.mail|nil|0,0 4x4", table.concat(members, " "))
  check("and that escaped pattern matches its own title",
    docs and string.find("Docs (draft) 100%", docs.window) ~= nil)
  check("an app with one window in the world carries no pattern", by_app["com.apple.mail"] ~= nil)
  check("minimized, unnamed, every-space and Hammerspoon's windows are not recorded but said",
    has_note(notes, "1 minimized") and has_note(notes, "1 Accessibility could not name")
      and has_note(notes, "on every space") and has_note(notes, "Hammerspoon's own"), notes_text(notes))
  local tv
  for _, a in ipairs(d1.spaces[1].apps) do if a.app == "com.apple.TV" then tv = a end end
  for _, a in ipairs(d1.spaces[2] and d1.spaces[2].apps or {}) do if a.app == "com.apple.TV" then tv = tv or a end end
  check("a full-screen window is recorded as fullscreen", tv and tv.layout == "fullscreen")
  check("a full-screen space takes no desktop slot: the laptop has two desktops", #d1.spaces == 2, tostring(#d1.spaces))
  local code = d1.spaces[2].apps[1]
  check("a window half a cell off is snapped and reported, never silently rounded",
    code and code.app == "com.microsoft.VSCode" and code.misfit ~= nil and has_note(notes, "spans part of a cell"),
    code and (tostring(code.layout) .. " " .. tostring(code.misfit)) or notes_text(notes))
  check("the Dock bindings are read and reported, and none is recorded",
    has_note(notes, "2 Dock bindings: 1 to all spaces, 1 to one space"), notes_text(notes))
  check("a panel with no windows is still recorded with its one desktop",
    #d3.spaces == 1 and #d3.spaces[1].apps == 0)
  check("the discovered desk plans against its own world with nothing but snapping places",
    only_places(desk, world))
end

-- One app on two displays, and one title inside another.
do
  local world = F.two_display_world()
  local desk = P.desk_from_world(world, {})
  local patterns = {}
  for _, d in ipairs(desk.displays) do
    for _, sp in ipairs(d.spaces) do
      for _, a in ipairs(sp.apps) do
        if a.app == "com.apple.mail" then patterns[#patterns + 1] = tostring(a.window) end
      end
    end
  end
  table.sort(patterns)
  check("an app with a window on each of two displays gets an anchored pattern on both",
    table.concat(patterns, " ") == "^Inbox %- 2 messages$ ^Inbox$", table.concat(patterns, " "))
  check("and the anchored pattern discover wrote for one title misses the title that contains it",
    patterns[2] ~= nil and string.find("Inbox - 2 messages", patterns[2]) == nil, tostring(patterns[2]))
  check("so that desk plans against its own world with nothing but snapping places",
    only_places(desk, world))
end

-- One app with one title on two displays: a pattern of it would claim both.
do
  local world = F.same_title_world()
  local desk, notes = P.desk_from_world(world, {})
  local news = 0
  for _, d in ipairs(desk.displays) do
    for _, sp in ipairs(d.spaces) do
      for _, a in ipairs(sp.apps) do
        if a.window == "^News$" then news = news + 1 end
      end
    end
  end
  check("a title one app's windows share on two displays is recorded on neither, and said for both",
    news == 0 and select(2, string.gsub(notes_text(notes), 'its title "News" does not tell it', "")) == 2,
    news .. " " .. notes_text(notes))
  local ok, why = only_places(desk, world)
  check("so that desk plans against its own world with nothing but snapping places", ok, why)
end

-- One app with a recorded window and a window on every space.
do
  local world = F.sticky_sibling_world()
  local desk = P.desk_from_world(world, {})
  local slack = desk.displays[2].spaces[1].apps[1]
  check("an app whose other window is on every space gets a pattern on its recorded one",
    slack ~= nil and slack.app == "com.tinyspeck.slackmacgap" and slack.window == "^Slack$",
    slack and tostring(slack.window))
  local ok, why = only_places(desk, world)
  check("so that desk leaves the every-space window alone when planned against its own world", ok, why)
end

-- Dock bindings that could not be read are said, never counted as none.
do
  local w = F.discover_world()
  w.app_bindings = {}
  w.prefs_errors = { spaces = "defaults export failed" }
  local desk, notes = P.desk_from_world(w, {})
  check("discover says the Dock bindings could not be read, and why, rather than 0 bindings",
    desk ~= nil and has_note(notes, "the Dock bindings could not be read: defaults export failed")
      and not has_note(notes, "0 Dock bindings"), notes_text(notes))
end

-- One app whose bundle id is written in two cases is one app, to discover as
-- to plan: its two windows need patterns, or each bare entry claims both.
do
  local world = F.discover_world()
  table.insert(world.screens[2].spaces[1].windows,
    F.win(270, "com.TinySpeck.SlackMacGap", "Slack Calls", -61, -1080, 960, 1055))
  local desk = P.desk_from_world(world, {})
  local bare = 0
  for _, a in ipairs(desk.displays[2].spaces[1].apps) do
    if a.window == nil then bare = bare + 1 end
  end
  check("an app whose bundle id comes in two cases is one app: both its windows carry a pattern", bare == 0,
    tostring(bare) .. " bare")
  check("so that desk plans against its own world with nothing but snapping places", only_places(desk, world))
end

-- The screen order in the world does not change the desk.
do
  local w = F.discover_world()
  local reversed = F.discover_world()
  local a, b, c = reversed.screens[1], reversed.screens[2], reversed.screens[3]
  reversed.screens = { c, b, a }
  check("discovering a world with its screens listed in another order gives the same desk",
    render((P.desk_from_world(w, {}))) == render((P.desk_from_world(reversed, {}))))
end

-- What observe could not read is refused, never recorded as empty.
do
  local w = F.discover_world()
  w.screens[1].spaces[3].type = nil
  w.screens[1].spaces[3].type_error = "spaceType failed"
  local desk, err = P.desk_from_world(w, {})
  check("discover refuses a space whose type could not be read", desk == nil and string.find(tostring(err), "spaceType failed", 1, true) ~= nil, err)
  local v = F.discover_world()
  v.screens[2].spaces[1].windows_error = "windowsForSpace failed"
  desk, err = P.desk_from_world(v, {})
  check("discover refuses a space whose windows could not be read", desk == nil and string.find(tostring(err), "windowsForSpace failed", 1, true) ~= nil, err)
  local u = F.discover_world()
  u.screens[3].spaces_error = "spacesForScreen failed"
  desk, err = P.desk_from_world(u, {})
  check("discover refuses a screen whose spaces could not be read", desk == nil and string.find(tostring(err), "spacesForScreen failed", 1, true) ~= nil, err)
end

do
  local lines = P.plan_report({})
  check("diff says so when nothing would change", lines[1] == "no change: this machine already matches the desk")
  local w = base_world()
  space(w, 1).windows[2].frame = { x = 300, y = 100, w = 500, h = 400 }
  local report = P.plan_report(P.plan(base_desk(), w, {}))
  check("diff prints one line per op, with its path and reason",
    #report == 1 and string.find(report[1], "place window 102 at 600,25 600x800 (displays[0].spaces[0].apps[1]): ", 1, true) == 1,
    report[1])
end

print(string.format("plan_test: %d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
