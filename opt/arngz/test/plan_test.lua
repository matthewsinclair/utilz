-- plan_test.lua: AT-03.2, the pure planner, under plain Lua (ST0026 D12);
-- and AT-05.2, display matching, below.
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

  -- issue 0133: an app that fixes its own window size cannot fill the cells a
  -- desk gives it. The slack is read from P.FRAME_SLACK, never written here,
  -- so these cases follow it if it ever changes.
  local slack, over = P.FRAME_SLACK, P.FRAME_SLACK + 1
  local at = function(x, y, w, h) return { x = x, y = y, w = w, h = h } end
  -- AT-01.2 (ST0032): origins_agree, through the frames_agree check below.
  check("origins_agree: the same origin, whatever the sizes",
    P.origins_agree(at(900, 40, 375, 667), at(900, 40, 450, 545)))
  check("origins_agree: within the slack on each axis, and not past it",
    P.origins_agree(at(900 + slack, 40 - slack, 10, 10), at(900, 40, 10, 10))
      and not P.origins_agree(at(900 + over, 40, 10, 10), at(900, 40, 10, 10))
      and not P.origins_agree(at(900, 40 + over, 10, 10), at(900, 40, 10, 10)))
  check("sizes_agree: the same size at different origins, and not past the slack",
    P.sizes_agree(at(0, 0, 450, 545), at(900, 40, 450, 545))
      and not P.sizes_agree(at(0, 0, 450 + over, 545), at(0, 0, 450, 545)))
  -- The regression guard on splitting frames_agree into the two: it must keep
  -- every answer it gave before, which is both halves and nothing else.
  check("frames_agree is still both halves, and nothing less",
    P.frames_agree(at(900, 40, 450, 545), at(900, 40, 450, 545))
      and not P.frames_agree(at(900, 40, 375, 667), at(900, 40, 450, 545))
      and not P.frames_agree(at(0, 40, 450, 545), at(900, 40, 450, 545))
      and not P.frames_agree(nil, at(900, 40, 450, 545))
      and not P.frames_agree(at(900, 40, 450, 545), nil))
  -- Appgate SDP's own numbers, from hv's menuz log at run 70, not invented.
  -- AT-01.1 (ST0032): the four place_outcome checks below.
  check("place_outcome: a window at its origin at a size the app enforces is own_size",
    P.place_outcome(at(900, 40, 375, 667), at(900, 40, 450, 545)) == "own_size")
  check("place_outcome: a window that took the frame it was given is placed",
    P.place_outcome(at(900, 40, 450, 545), at(900, 40, 450, 545)) == "placed")
  -- The one thing this must not swallow: a window of the right size in the
  -- wrong place is a failure, not a size the app chose.
  check("place_outcome: the right size at the wrong origin is failed",
    P.place_outcome(at(0, 40, 450, 545), at(1920, 40, 450, 545)) == "failed")
  check("place_outcome: a frame that could not be read is failed",
    P.place_outcome(nil, at(900, 40, 450, 545)) == "failed")

  -- issue 0134: a window is on the display its centre is on.
  local screen = at(0, 25, 1200, 800)
  -- AT-02.1 (ST0032): the mostly_off checks below.
  check("mostly_off: a window wholly inside its display is not off it",
    not P.mostly_off(at(0, 25, 600, 800), screen))
  check("mostly_off: a window hanging over an edge with its centre still inside is not off it",
    not P.mostly_off(at(-100, 25, 600, 800), screen))
  -- Run 69's case: 1920 points left of the origin, which is where homere's
  -- left monitor sits.
  check("mostly_off: left, right, above and below are each off it",
    P.mostly_off(at(-1920, 25, 600, 800), screen)
      and P.mostly_off(at(1200, 25, 600, 800), screen)
      and P.mostly_off(at(0, -1080, 600, 800), screen)
      and P.mostly_off(at(0, 825, 600, 800), screen))
  -- The boundary is half open, as a screen's extent is: a centre exactly on
  -- the far edge belongs to the next display, not this one.
  check("mostly_off: a window whose centre sits exactly on the far edge is off it",
    P.mostly_off(at(screen.x + screen.w - 1, 25, 2, 2), screen))
  check("mostly_off: a window whose centre sits exactly on the near edge is not off it",
    not P.mostly_off(at(screen.x - 1, 25, 2, 2), screen))
  check("mostly_off: nothing to compare is not off it",
    not P.mostly_off(nil, screen) and not P.mostly_off(at(0, 0, 1, 1), nil))
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

-- An app not running is not_running, said and uncounted, in either plan:
-- apply never launches an app (ST6d8eed9 AC-35219619.1). AT-35219619.1
-- (ST6d8eed9 acceptance.md) cites this arm and the next.
do
  local w = base_world()
  w.apps_running = { "com.apple.mail", "com.microsoft.VSCode" }
  table.remove(space(w, 1).windows, 2)
  local ops = P.plan(base_desk(), w, {})
  check("an app not running is not_running, uncounted, with a reason and the entry's path",
    kinds(ops) == "not_running" and ops[1].bundle == "com.apple.Safari" and ops[1].uncounted == true
      and ops[1].reason ~= nil and ops[1].path == "displays[0].spaces[0].apps[1]", ops_text(ops))
  local never = P.plan(base_desk(), w, { running_before = {} })
  check("a second plan says the same of one that was not running when apply began",
    kinds(never) == "not_running" and never[1].uncounted == true, ops_text(never))
  local before = P.plan(base_desk(), w, { running_before = { ["com.apple.safari"] = true } })
  check("a second plan reports an app that quit since apply began as gone, counted",
    kinds(before) == "gone" and string.find(before[1].reason, "was running when apply began", 1, true) ~= nil
      and not before[1].uncounted, ops_text(before))
  check("and no plan holds a launch", not string.find(kinds(ops) .. kinds(never) .. kinds(before), "launch", 1, true))
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
  -- The filter ran, as observe notes it: the WP6 check below reads this world.
  v.window_filter = "ran"
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
  -- AT-322a6511.2 (STca1b7f9 acceptance.md) cites this arm.
  -- STca1b7f9 WP6 (issue I7fce35c): a failed filter is said plainly, with
  -- its way out, which travels with the unseen op to Finished.
  check("an unseen reason counts the window id reads that failed, and says plainly that Hammerspoon's window filter failed",
    kinds(uops) == "unseen"
      and string.find(uops[1].reason, "2 window id read(s) failed (axuielement gone)", 1, true) ~= nil
      and string.find(uops[1].reason, "; Hammerspoon's window filter failed (no filter), so windows on desktops not shown"
        .. " could not be named", 1, true) ~= nil,
    uerr or ops_text(uops))
  check("WP6: with the filter failed, an unseen op carries the fix: run it again, then reload Hammerspoon's config",
    uops and uops[1] and uops[1].fix
      == "run it again; if it fails again, reload Hammerspoon's config (Reload Config in its menu)",
    uops and uops[1] and tostring(uops[1].fix))
  check("WP6: with the filter run, as observe notes it, an unseen op carries no fix and names no filter",
    vops and vops[1] and vops[1].fix == nil and not string.find(vops[1].reason, "window filter", 1, true),
    vops and vops[1] and tostring(vops[1].fix))
  check("WP6: the filter failed is read one way: a note that is not 'ran', and not a missing one",
    P.filter_failed({ window_filter = "failed: x" }) and not P.filter_failed({ window_filter = "ran" })
      and not P.filter_failed({}))
end

-- ST6d8eed9 WP a45b3aeb: an unseen op planned while the filter failed carries
-- the filter's words, which ask for a reload when the request lets it; and a
-- plan after the reload gives the next way out.
do
  local u = base_world()
  table.remove(space(u, 1).windows, 2)
  u.window_filter = "failed: hs/uielement.lua:134"
  local ops = P.plan(base_desk(), u, {})
  local words = P.filter_words(u)
  -- AC-a45b3aeb.2 cites this arm, and AT-a45b3aeb.2 (ST6d8eed9 acceptance.md)
  -- with log_test.lua's arm "a reload asked for by the read after the creates".
  check("ST6d8eed9: an unseen op planned while the filter failed carries its words, which ask for a reload"
    .. " when the request lets it",
    kinds(ops) == "unseen" and ops[1].filter == words and words == "Hammerspoon's window filter failed (hs/uielement.lua:134)"
      and P.reload_reason(ops, true) == words,
    ops_text(ops) .. " / " .. tostring(P.reload_reason(ops, true)))
  check("ST6d8eed9: a request that does not let the engine ask gets no reload",
    P.reload_reason(ops, false) == nil and P.reload_reason(ops, nil) == nil)
  local v = base_world()
  table.remove(space(v, 1).windows, 2)
  v.window_filter = "ran"
  local vops = P.plan(base_desk(), v, {})
  check("ST6d8eed9: an unseen op with the filter run asks for no reload, since a reload gives it nothing",
    kinds(vops) == "unseen" and vops[1].filter == nil and P.reload_reason(vops, true) == nil, ops_text(vops))
  local none = P.plan(base_desk(), base_world(), {})
  check("ST6d8eed9: a plan with no unseen op asks for no reload", P.reload_reason(none, true) == nil, ops_text(none))
  local after = P.plan(base_desk(), u, { after_reload = true })
  check("ST6d8eed9: after the reload, an unseen op from a filter that failed again carries the next way out",
    after and after[1] and after[1].fix == P.FILTER_FIX_AFTER_RELOAD
      and string.find(P.FILTER_FIX_AFTER_RELOAD, "quit Hammerspoon, open it again", 1, true) ~= nil,
    after and after[1] and tostring(after[1].fix))
end

-- Which unseen op counts (issue 0132): plan marks one uncounted only when no
-- window read failed, since the window not read may be the entry's, and
-- diff's exit, P.plan_exit, counts every op without the mark.
do
  -- diff's exit for these ops, or nil when plan cannot give one.
  local function exit_of(ops)
    local ok, c = pcall(P.plan_exit, ops)
    if ok then return c end
    return nil
  end
  local ops = P.plan(base_desk(), F.unseen_world(), {})
  check("an app running with its window closed plans one unseen op, marked uncounted, and diff's exit is 0 (issue 0132)",
    kinds(ops) == "unseen" and ops[1].uncounted == true and exit_of(ops) == 0,
    ops_text(ops) .. ", exit " .. tostring(exit_of(ops)))
  local failed_reads = {
    { "a window that could not be read", function()
      local w = F.unseen_world()
      local windows = space(w, 1).windows
      windows[#windows + 1] = { id = 104, named = false, read_error = "incorrect type 'nil'" }
      return w
    end },
    { "a window id read that failed", function()
      local w = F.unseen_world()
      w.window_id_errors, w.window_id_error = 1, "axuielement gone"
      return w
    end },
    { "the window filter failing", F.unseen_unread_world },
  }
  for _, case in ipairs(failed_reads) do
    local cops = P.plan(base_desk(), case[2](), {})
    check("an unseen op planned beside " .. case[1] .. " is counted, and diff's exit is 1 (issue 0132)",
      kinds(cops) == "unseen" and cops[1].uncounted == false and exit_of(cops) == 1,
      ops_text(cops) .. ", exit " .. tostring(exit_of(cops)))
  end
  local m = F.unseen_world()
  space(m, 1).windows[1].frame = { x = 300, y = 100, w = 500, h = 400 }
  local mops = P.plan(base_desk(), m, {})
  check("an uncounted unseen op beside a place leaves diff's exit at 1 (issue 0132)",
    kinds(mops) == "place,unseen" and exit_of(mops) == 1, ops_text(mops) .. ", exit " .. tostring(exit_of(mops)))
  check("a plan with no op gives diff's exit 0 (issue 0132)", exit_of({}) == 0, "exit " .. tostring(exit_of({})))
end

-- What observe asks about, fresh: each of the desk's apps once, in desk order.
do
  local d = base_desk()
  table.insert(d.displays[1].spaces[2].apps, { app = "COM.APPLE.MAIL", window = "Drafts", layout = "0,0 6x8" })
  check("desk_bundles lists each desk app once, in desk order, whatever its case",
    table.concat(P.desk_bundles(d), ",") == "com.apple.mail,com.apple.Safari,com.microsoft.VSCode",
    table.concat(P.desk_bundles(d), ","))
end

-- A world whose running apps could not be listed is refused, never read as
-- every app not running.
do
  local noapps = base_world()
  noapps.apps_running_error = "hs.application.runningApplications: axuielement"
  local nops, nerr = P.plan(base_desk(), noapps, {})
  check("plan refuses a world whose running apps could not be listed, never calling what runs not running",
    nops == nil and string.find(tostring(nerr), "running apps could not be listed", 1, true) ~= nil, nerr or ops_text(nops))
end

-- AT-93ea7f8a.2: a desktop listed on two screens orders neither: plan and discover both
-- refuse it, naming both screens, before anything changes (WP 93ea7f8a).
do
  local w = base_world()
  w.screens[2] = { uuid = "SCREEN-B", spaces = { { id = space(w, 1).id, ordinal = 1, type = "user", windows = {} } } }
  local ops, err = P.plan(base_desk(), w, {})
  local want = string.format("desktop %s is listed on two screens, SCREEN-A and SCREEN-B", tostring(space(w, 1).id))
  check("plan refuses a desktop listed on two screens, naming both",
    ops == nil and string.find(tostring(err), want, 1, true) ~= nil, err or ops_text(ops))
  local desk, derr = P.desk_from_world(w, {})
  check("and discover refuses it in the same words", desk == nil and string.find(tostring(derr), want, 1, true) ~= nil,
    tostring(derr))
  local twice = base_world()
  local first = space(twice, 1)
  table.insert(twice.screens[1].spaces, { id = first.id, ordinal = #twice.screens[1].spaces + 1, type = "user", windows = {} })
  local tops, terr = P.plan(base_desk(), twice, {})
  local twice_want = string.format("desktop %s is listed twice on screen SCREEN-A", tostring(first.id))
  check("plan refuses a desktop listed twice on one screen, by name",
    tops == nil and string.find(tostring(terr), twice_want, 1, true) ~= nil, terr or ops_text(tops))
end

-- AT-93ea7f8a.2: a lone desktop whose record is not current takes a new desktop beside it,
-- in place of issue 0077's refusal (WP 93ea7f8a). That apply then takes one fresh read
-- of the world and waits on nothing else is log_test.lua's arm 17 (AT-93ea7f8a.7).
do
  local w = base_world()
  local vscode = table.remove(w.screens[1].spaces, 2).windows[1]
  table.insert(space(w, 1).windows, vscode)
  local _, source = P.order_spaces({ space(w, 1).id }, {})
  w.screens[1].order_source = source
  local ops = P.plan(base_desk(), w, {})
  check("a lone desktop ordered from the live list takes a new desktop beside it",
    source == "live" and ops ~= nil and ops[1] ~= nil and ops[1].op == "create_space", tostring(source) .. " " .. ops_text(ops))
  local without = P.plan(base_desk(), w, { no_create = true })
  check("and under --no-create it plans as before, creating nothing", kinds(without) == "no_space", ops_text(without))
end

-- One app a desk names in two cases is one app: each of its entries is
-- not_running, and the tally names it once (ST6d8eed9 AC-35219619.1).
do
  local w = base_world()
  w.apps_running = {}
  local d = base_desk()
  d.displays[1].spaces[2].apps[1].app = "com.Apple.Mail"
  d.displays[1].spaces[2].apps[1].window = "^nothing$"
  table.insert(d.displays[1].spaces[1].apps, { app = "com.apple.mail", window = "^nothing either$", layout = "0,0 1x1" })
  local entries = 0
  for _, dd in ipairs(d.displays) do
    for _, sp in ipairs(dd.spaces) do
      for _, a in ipairs(sp.apps) do
        if string.lower(a.app) == "com.apple.mail" then entries = entries + 1 end
      end
    end
  end
  local ops = P.plan(d, w, {})
  local mail, results = 0, {}
  for _, op in ipairs(ops or {}) do
    if op.op == "not_running" and string.lower(op.bundle) == "com.apple.mail" then mail = mail + 1 end
    results[#results + 1] = { op = op.op, path = op.path, status = op.op, reason = op.reason, bundle = op.bundle,
      uncounted = op.uncounted }
  end
  check("each entry of an app a desk names in two cases is not_running", entries > 1 and mail == entries, ops_text(ops))
  local _, code, tally = P.apply_report(d, results)
  local _, named = string.gsub(string.lower(tally.not_running_apps or ""), "com%.apple%.mail", "")
  check("and the tally names it once, with exit 0", code == 0 and named == 1, tostring(tally.not_running_apps))
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
  -- A refusal is Finished's first, so it names the window by its id and never
  -- its title (issue I4eacd29).
  check("a pattern that fails only on a real title is refused naming its path and window id, with no title",
    ok and ops == nil and err ~= nil and string.find(err, "displays[0].spaces[1].apps[0].window is not a valid Lua"
      .. " pattern on the title of window 103: ", 1, true) == 1 and not string.find(err, "Utilz 1", 1, true),
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
  local all = seen.create_space and seen.not_running and seen.move and seen.place and seen.unseen
  check("one world yields every op kind it can", all, ops_text(ops))
  -- The kinds one world cannot yield beside those: each from its own world.
  local more = {}
  local nl = base_world()
  nl.apps_running = { "com.apple.mail", "com.microsoft.VSCode" }
  table.remove(space(nl, 1).windows, 2)
  for _, op in ipairs(P.plan(base_desk(), nl, { running_before = { ["com.apple.safari"] = true } }) or {}) do
    more[#more + 1] = op
  end
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
  -- ST6d8eed9 WP 88504807: an empty third desktop is removed, and one that
  -- holds a window only it lists is kept as an extra.
  local spare = base_world()
  table.insert(spare.screens[1].spaces, { id = 13, ordinal = 3, type = "user", uuid = "SPACE-13", windows = {} })
  for _, op in ipairs(P.plan(base_desk(), spare, {}) or {}) do more[#more + 1] = op end
  local kept = base_world()
  table.insert(kept.screens[1].spaces, { id = 13, ordinal = 3, type = "user", uuid = "SPACE-13",
    windows = { win(104, "com.apple.Notes", "Notes", 0, 25, 300, 300) } })
  for _, op in ipairs(P.plan(base_desk(), kept, {}) or {}) do more[#more + 1] = op end
  for _, op in ipairs(more) do
    seen[op.op] = true
    if not op.reason then missing[#missing + 1] = op.op end
  end
  local every = { "create_space", "not_running", "move", "place", "unseen", "gone", "unmovable", "no_space", "pending",
    "remove_space", "extra" }
  local absent = {}
  for _, k in ipairs(every) do
    if not seen[k] then absent[#absent + 1] = k end
  end
  check("between them, the worlds yield every op kind", #absent == 0, table.concat(absent, ","))
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

-- AT-05.2: display matching refuses rather than guesses.
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

-- ------------------------------------------------ space order (WP 93ea7f8a)
-- AT-93ea7f8a.1

print("space order")
do
  local function list(display, ids)
    local spaces = {}
    for i, id in ipairs(ids) do spaces[i] = { ManagedSpaceID = id } end
    return { ["Display Identifier"] = display, Spaces = spaces }
  end
  local function text(ids) return ids and table.concat(ids, ",") or "nil" end

  -- hv's plist, measured 16 Oct 2026: the live list read 1, 3, 2588, 305 and
  -- the record 1, 3, 2588, 1733, and ctrl+right from 2588 went to 1733. Where
  -- one list holds a screen's live desktops exactly, the record is current,
  -- and its order is taken, the live one said beside it.
  local monitors = { list("Main", { 1, 3, 2588, 1733, 305 }), list("34791BF3", { 2634 }), { ["Display Identifier"] = "6F89E131" } }
  local order, source, note = P.order_spaces({ 1, 3, 2588, 305, 1733 }, monitors)
  check("a current record's order is taken over the live list's (16 Oct)",
    text(order) == "1,3,2588,1733,305" and source == "record", text(order) .. " " .. tostring(source))
  check("and the log is told how the live order differs",
    note ~= nil and string.find(note, "the live order differs: 1 3 2588 305 1733", 1, true) ~= nil, tostring(note))
  local same, ssource, snote = P.order_spaces({ 1, 3, 2588, 1733, 305 }, monitors)
  check("a record the live order agrees with is taken, with nothing to say",
    text(same) == "1,3,2588,1733,305" and ssource == "record" and snote == nil, tostring(snote))
  local later = { monitors[1], list("2F1BFA83", { 3216, 3215 }), monitors[3] }
  local found, fsource = P.order_spaces({ 3215, 3216 }, later)
  check("a screen's list is the one holding exactly its desktops, wherever it sits, never chosen by its name",
    text(found) == "3216,3215" and fsource == "record", text(found))

  -- hv's diagnosis run, 23 Nov 2026. com.apple.spaces lags one display change
  -- behind, so after each change no list holds a screen's live desktops, and
  -- the live order is taken. Its full-screen spaces, 423 and 121, are in it
  -- like any desktop.
  local collapsed = { ["Display Identifier"] = "B6EB478C", ["Collapsed Space"] = { ManagedSpaceID = 99 } }
  local plugged = { list("Main", { 1, 3, 1431, 5, 423, 121, 6, 7 }), list("34791BF3", { 1716, 1271, 1442 }),
    list("2F1BFA83", { 1586 }), collapsed }
  local unplugged_live = { 1, 3, 1431, 5, 423, 121, 6, 7, 1271, 1442 }
  local unplugged, usource, unote = P.order_spaces(unplugged_live, plugged)
  check("unplugged, with the record still at the plugged layout: the live order, and why",
    text(unplugged) == text(unplugged_live) and usource == "live"
      and string.find(tostring(unote), "no list in com.apple.spaces holds exactly these desktops", 1, true) ~= nil,
    text(unplugged) .. " " .. tostring(usource) .. " " .. tostring(unote))
  -- At the replug's flap macOS wrote the unplugged layout, which is the order
  -- taken above: the live order is what macOS itself recorded.
  local flap = { list("Main", unplugged_live), collapsed }
  local recorded, fsource, fnote = P.order_spaces(unplugged_live, flap)
  check("the record macOS wrote at the flap holds the unplugged desktops exactly, so it is taken, with nothing to say",
    text(recorded) == text(unplugged) and fsource == "record" and fnote == nil,
    text(recorded) .. " " .. tostring(fsource) .. " " .. tostring(fnote))
  local builtin_live = { 1, 3, 1431, 5, 423, 121, 6, 7 }
  local builtin, bsource = P.order_spaces(builtin_live, flap)
  local aleft, asource = P.order_spaces({ 1808, 1271, 1442 }, flap)
  local aright, rsource = P.order_spaces({ 1811 }, flap)
  check("replugged, with the record at the unplugged layout: each display in its live order",
    text(builtin) == text(builtin_live) and bsource == "live" and text(aleft) == "1808,1271,1442" and asource == "live"
      and text(aright) == "1811" and rsource == "live",
    table.concat({ text(builtin), text(aleft), text(aright) }, " / "))
  local fullscreen = { [423] = true, [121] = true }
  local screen = { uuid = "37D8832A", spaces = {} }
  for i, id in ipairs(builtin) do
    screen.spaces[i] = { id = id, ordinal = i, type = fullscreen[id] and "fullscreen" or "user", windows = {} }
  end
  local desktops = {}
  for i, sp in ipairs(P.user_spaces(screen)) do desktops[i] = sp.id end
  -- Each full-screen space where the live list puts it, and the desktops
  -- besides them in the live list's order: what the order and the desk
  -- ordinals keep.
  local placed, want = true, {}
  for i, id in ipairs(builtin_live) do
    if fullscreen[id] then
      placed = placed and builtin[i] == id
    else
      want[#want + 1] = id
    end
  end
  check("its full-screen spaces sit where the live list puts them, and desk ordinals skip them",
    placed and text(desktops) == text(want), text(desktops))
  local doubled, dsource = P.order_spaces({ 1, 2 }, { list("Main", { 2, 2 }) })
  check("a list that names a desktop twice is never a screen's list, though its size matches",
    text(doubled) == "1,2" and dsource == "live", text(doubled) .. " " .. tostring(dsource))

  local twice, tsource, tnote = P.order_spaces({ 3215, 3216 }, { later[2], later[2] })
  check("two lists that both hold a screen's desktops: the live order, and both said",
    text(twice) == "3215,3216" and tsource == "live" and string.find(tostring(tnote), "two lists", 1, true) ~= nil,
    tostring(tnote))
  local fewer, fsource2 = P.order_spaces({ 1, 3 }, monitors)
  check("a list holding more than the screen's desktops is not its list", text(fewer) == "1,3" and fsource2 == "live")
  local alone, asource2 = P.order_spaces({ 3215 }, monitors)
  check("a lone desktop no list holds is its own order", text(alone) == "3215" and asource2 == "live")
  local pair, psource, pnote = P.order_spaces({ 3215, 3216 }, nil, "defaults export failed")
  check("with no display configuration: the live order, saying why",
    text(pair) == "3215,3216" and psource == "live"
      and string.find(tostring(pnote), "carries no display configuration: defaults export failed", 1, true) ~= nil,
    tostring(pnote))
end

-- --------------------------------------- the displays settle (WP 93ea7f8a)
-- AT-93ea7f8a.4

print("the displays settle")
do
  local now = 1795000000
  local long_ago = now - 2 * P.QUIET_LIMIT
  local verdict = P.quiet_verdict(now, { started = long_ago }, now)
  check("a watcher that has seen no change for long enough: go", verdict == "go", verdict)
  verdict = P.quiet_verdict(now, { started = long_ago, last_change = now - P.QUIET_SECONDS }, now)
  check("a last change QUIET_SECONDS ago: go", verdict == "go", verdict)
  local wait
  verdict, wait = P.quiet_verdict(now, { started = long_ago, last_change = now - 1 }, now)
  check("a change a second ago: wait out the rest of QUIET_SECONDS",
    verdict == "wait" and wait == P.QUIET_SECONDS - 1, tostring(verdict) .. " " .. tostring(wait))
  verdict, wait = P.quiet_verdict(now, { started = now - 1 }, now)
  check("a watcher started a second ago has seen nothing yet: it waits the same",
    verdict == "wait" and wait == P.QUIET_SECONDS - 1, tostring(verdict) .. " " .. tostring(wait))
  verdict, wait = P.quiet_verdict(now, nil, now - 1)
  check("with no watcher, quiet counts from when the wait began",
    verdict == "wait" and wait == P.QUIET_SECONDS - 1, tostring(verdict) .. " " .. tostring(wait))
  verdict = P.quiet_verdict(now, nil, now - P.QUIET_SECONDS)
  check("and goes once QUIET_SECONDS have passed", verdict == "go", verdict)
  local began = now - (P.QUIET_LIMIT - 1)
  verdict, wait = P.quiet_verdict(now, { started = long_ago, last_change = now }, began)
  check("a wait is never asked to run past QUIET_LIMIT", verdict == "wait" and wait == 1, tostring(verdict) .. " " .. tostring(wait))
  local why, fix
  verdict, why, fix = P.quiet_verdict(now, { started = long_ago, last_change = now - 1 }, now - P.QUIET_LIMIT)
  check("displays still changing at QUIET_LIMIT: refuse, saying so, with the fix",
    verdict == "refuse" and string.find(tostring(why), "the displays did not settle in " .. P.QUIET_LIMIT .. " s", 1, true) ~= nil
      and fix == "run it again once the displays have stopped changing",
    tostring(verdict) .. " / " .. tostring(why) .. " / " .. tostring(fix))
end

-- ---------------------------- the pointer is still (ST6d8eed9 WP 4cb617e2)

-- AT-4cb617e2.1 (ST6d8eed9 acceptance.md) cites this arm.
-- AC-4cb617e2.1 cites this arm: still after STILL_SECONDS within STILL_PX
-- with hands free, a wait before that, and a give-up at PAUSE_LIMIT.
print("the pointer is still")
do
  local began = 1795000000
  local at = { x = 500, y = 400 }
  local verdict, look = P.still_verdict(began, nil, at, true, began)
  check("still: the first look waits, and keeps where the pointer is and when",
    verdict == "wait" and look ~= nil and look.at.x == at.x and look.at.y == at.y and look.since == began,
    tostring(verdict))
  local near = { x = at.x + P.STILL_PX, y = at.y }
  local still, kept = P.still_verdict(began + P.STILL_SECONDS, look, near, true, began)
  check("still: within STILL_PX of one point, with hands free, for STILL_SECONDS, is still",
    still == "still" and kept.since == began, tostring(still))
  check("still: before STILL_SECONDS it waits",
    P.still_verdict(began + P.STILL_SECONDS / 2, look, near, true, began) == "wait")
  local far = { x = at.x + P.STILL_PX + 1, y = at.y }
  local moved, again = P.still_verdict(began + P.STILL_SECONDS, look, far, true, began)
  check("still: a pointer past STILL_PX waits, and the look starts again where it is now",
    moved == "wait" and again.since == began + P.STILL_SECONDS and again.at.x == far.x, tostring(moved))
  local held, none = P.still_verdict(began + P.STILL_SECONDS, look, at, false, began)
  check("still: a mouse button or modifier key held is never still, and the look starts again",
    held == "wait" and none == nil, tostring(held))
  check("still: a pointer not still for STILL_SECONDS by PAUSE_LIMIT gives up",
    P.still_verdict(began + P.PAUSE_LIMIT, look, far, true, began) == "give_up")
  check("still: a pointer still for STILL_SECONDS at the limit itself is still, not a give-up",
    P.still_verdict(began + P.PAUSE_LIMIT, { at = at, since = began + P.PAUSE_LIMIT - P.STILL_SECONDS }, at, true, began)
      == "still")
  check("note: a pause is said in whole seconds rounded up, so never 0 s",
    P.paused_note(0.2) == "paused 1 s for the pointer" and P.paused_note(2) == "paused 2 s for the pointer"
      and P.paused_note(2.01) == "paused 3 s for the pointer", P.paused_note(0.2))
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

  -- vc's grab probes at 45acc46: TextEdit follows the full 30, Console 25,
  -- Calculator 1; Dictionary and Stickies 0.
  local before = { x = 128, y = 40, w = 600, h = 400 }
  check("a hold took when the frame followed the nudge",
    P.hold_took(before, { x = 153, y = 40, w = 600, h = 400 }, 30) == true)
  check("a hold took when the frame moved a point toward a nudge left",
    P.hold_took(before, { x = 127, y = 40, w = 600, h = 400 }, -30) == true)
  check("a hold took when the frame moved one point toward a nudge right, as Calculator's did",
    P.hold_took(before, { x = 129, y = 40, w = 600, h = 400 }, 30) == true)
  local held, why_held = P.hold_took(before, { x = 128, y = 40, w = 600, h = 400 }, 30)
  check("a hold did not take when the frame stayed put",
    held == nil and string.find(why_held, "did not follow the pointer", 1, true) ~= nil, tostring(why_held))
  local _, why_away = P.hold_took(before, { x = 120, y = 40, w = 600, h = 400 }, 30)
  check("a frame that moved away from a nudge right is not a hold, and says where it went and the nudge",
    why_away == "its frame did not follow the pointer (x 128 to 120 after a nudge of 30)", tostring(why_away))
  check("a frame that moved away from a nudge left is not a hold",
    P.hold_took(before, { x = 130, y = 40, w = 600, h = 400 }, -30) == nil)
  check("an unread frame is not a hold", P.hold_took(before, nil, 30) == nil)

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
  -- The names a real move carries are P.display_names' (arngz.lua sets them
  -- from ctx.names), so the display reads as the desk names it.
  local none, why, nfix = P.move_legs(now, { screen = "L", space = 2588, from_screen = "L", from_space = 3,
    names = { L = "left" } })
  check("a carry past a full-screen space with no display to go round through fails, saying so, desktops as the desk counts them",
    none == nil and why == "a window not moved to desktop 3 on left: an app arngz cannot name is full screen between desktop 2 and desktop 3"
      and nfix == "take it out of full screen, or attach a display, then run it again", tostring(why) .. " / " .. tostring(nfix))
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

  -- STca1b7f9 WP3 and WP4, on the orders hv's runs of 23 Nov logged. rhad's
  -- re-run (20261123T104723Z-91703), the built-in alone: Screen Sharing's
  -- gyges full screen on 423 and Parallels' kovacs on 121, and Teams wanted
  -- from 5 on 7. zeopit's run (20261123T105242Z-55488), plugged in under two
  -- panels: Appgate wanted from 6 on 7, past 121 and 423.
  local rhad_order = { 1, 3, 1431, 5, 423, 121, 6, 7, 1271, 1442 }
  local types = {}
  for _, id in ipairs(rhad_order) do types[id] = "user" end
  types[423], types[121] = "fullscreen", "fullscreen"
  local apps = { [423] = { { app = "Screen Sharing", title = "gyges" } },
    [121] = { { app = "Parallels Desktop", title = "kovacs" } } }
  local names = { L = "main", B = "above-left", A = "above-right", F = "far" }
  local teams = { screen = "L", space = 7, ordinal = 6, from_screen = "L", from_space = 5, app = "Microsoft Teams",
    names = names }
  local rhad = { order = { L = rhad_order }, types = types, active = { L = 5 }, screens = { laptop }, apps = apps }
  local fail, fwhy, ffix, fpassed = P.move_legs(rhad, teams)
  -- AT-ad94d40b.1 (STca1b7f9 acceptance.md) cites this arm.
  check("WP4: on the laptop alone, the move fails naming its app, the target, every full-screen app and the gap",
    fail == nil and fwhy == "Microsoft Teams not moved to desktop 6 on main: Screen Sharing and Parallels Desktop are full"
      .. " screen between desktop 4 and desktop 6", tostring(fwhy))
  check("WP4: with no other display the fix is to attach one",
    ffix == "take them out of full screen, or attach a display, then run it again", tostring(ffix))
  check("WP4: the failure's words carry no window title, and the full-screen windows go to the log with theirs",
    not string.find(fwhy, "gyges", 1, true) and not string.find(ffix, "kovacs", 1, true) and fpassed and #fpassed == 2
      and fpassed[1].title == "gyges" and fpassed[1].space == 423 and fpassed[2].app == "Parallels Desktop",
    fpassed and #fpassed)

  local zeopit_order = { 1, 3, 1431, 5, 7, 423, 121, 6 }
  -- The panels' desktops: 8 and 9 user, 10 and 12 full screen; 13 the far
  -- display's user desktop.
  local ztypes = { [8] = "user", [9] = "user", [10] = "fullscreen", [11] = "user", [12] = "fullscreen", [13] = "user" }
  for _, id in ipairs(zeopit_order) do ztypes[id] = types[id] or "user" end
  local appgate = { screen = "L", space = 7, ordinal = 5, from_screen = "L", from_space = 6, app = "Appgate SDP",
    names = names }
  local function zeopit(left_shows, right_shows, screens)
    return { order = { L = zeopit_order, B = { 8, 10 }, A = { 9, 11, 12 }, F = { 13, 10 } }, types = ztypes,
      active = { L = 6, B = left_shows, A = right_shows, F = 13 }, screens = screens or { laptop, left, right },
      apps = apps }
  end
  local went = P.move_legs(zeopit(8, 9), appgate)
  -- AT-dca427e7.1 (STca1b7f9 acceptance.md) cites this arm.
  check("WP3: plugged in, a carry past full-screen spaces goes round through a panel, the first by the screens' order",
    went and went.via == "B" and #went == 3, went and (tostring(went.via) .. " / " .. #went))
  local function legs_text(legs)
    local out = {}
    for i, leg in ipairs(legs or {}) do
      out[i] = string.format("%s %s>%s %s [%s]%s", tostring(leg.kind), tostring(leg.from_screen), tostring(leg.screen),
        tostring(leg.space), table.concat(leg.steps or {}, ","), leg.check and " check" or "")
    end
    return table.concat(out, " | ") .. " (checked " .. tostring(legs and legs.checked) .. ")"
  end
  check("WP3: the legs are a drag to B, read back, then A steps past with nothing held, then a drag back",
    went and went[1].kind == "drag" and went[1].from_screen == "L" and went[1].screen == "B" and went[1].space == 8
      and went[1].check == true and went.checked == 1
      and went[2].kind == "switch" and went[2].screen == "L" and table.concat(went[2].steps, ",") == "121,423,7"
      and went[2].side == "left"
      and went[3].kind == "drag" and went[3].from_screen == "B" and went[3].screen == "L" and went[3].space == 7
      and not went[3].check, legs_text(went))
  local shown_elsewhere = zeopit(8, 9)
  shown_elsewhere.active.L = 1
  local first_switch = P.move_legs(shown_elsewhere, appgate)
  check("WP3: a window on a desktop its display is not showing: A shows it first, nothing held",
    first_switch and #first_switch == 4 and first_switch[1].kind == "switch" and first_switch[1].screen == "L"
      and first_switch.checked == 2 and first_switch[2].check == true, first_switch and #first_switch)
  local right_only = P.move_legs(zeopit(10, 9), appgate)
  check("WP3: a panel showing a full-screen space is not gone round through",
    right_only and right_only.via == "A" and right_only[1].screen == "A" and right_only[1].space == 9,
    right_only and tostring(right_only.via))
  local both, bwhy2, bfix = P.move_legs(zeopit(10, 12), appgate)
  check("WP4: panels that each show a full-screen space: the fix names the one the route would take",
    both == nil and bfix == "take them out of full screen, or show a desktop on above-left, then run it again"
      and string.find(bwhy2, "Appgate SDP not moved to desktop 5 on main: ", 1, true) == 1,
    tostring(bwhy2) .. " / " .. tostring(bfix))
  local apart, _, afix = P.move_legs(zeopit(8, 9, { laptop, far }), appgate)
  check("WP4: a display that shares no edge with A: the fix is to arrange it to",
    apart == nil and afix == "take them out of full screen, or arrange far to share an edge with main, then run it again",
    tostring(afix))
  local far_full = zeopit(8, 9, { laptop, far })
  far_full.active.F = 10
  local _, _, ffull = P.move_legs(far_full, appgate)
  check("WP4: and to show a desktop on it, when it shows a full-screen space too",
    ffull == "take them out of full screen, or arrange far to share an edge with main and show a desktop on it, then run it again",
    tostring(ffull))
  local one = { order = rhad.order, types = types, active = rhad.active, screens = { laptop },
    apps = { [423] = apps[423] } }
  local _, owhy, ofix = P.move_legs(one, { screen = "L", space = 6, ordinal = 5, from_screen = "L", from_space = 5,
    app = "Microsoft Teams", names = names })
  check("WP4: one full-screen app named, one that cannot be: both said, and 'them'",
    owhy == "Microsoft Teams not moved to desktop 5 on main: Screen Sharing and an app arngz cannot name are full screen"
      .. " between desktop 4 and desktop 5" and string.find(ofix, "take them", 1, true) == 1, tostring(owhy))

  -- AT-dca427e7.2 (STca1b7f9 acceptance.md) cites this arm.
  -- WP3: where a round that failed after its first drag left the window.
  local zs = zeopit(8, 9)
  check("WP3: a round that failed after its first drag says where the window is now, as ic worded it, with no fix",
    P.round_failure(zs, appgate, { screen = "B", space = 8 }, nil, "drag: the hold did not take window 166")
      == "Appgate SDP not moved to desktop 5 on main, and now on above-left's desktop 1: drag: the hold did not take window 166",
    P.round_failure(zs, appgate, { screen = "B", space = 8 }, nil, "x"))
  local unread_where = P.round_failure(zs, appgate, nil, "windowSpaces(166): nil", "switch: x")
  check("WP3: and says so when where it is could not be read",
    unread_where
      == "Appgate SDP not moved to desktop 5 on main, and where it is now could not be read (windowSpaces(166): nil): switch: x",
    unread_where)
  local off_map = P.round_failure(zs, appgate, { screen = "B", space = 77 }, nil, "x")
  check("WP3: a desktop not in the display's order is said as a space id, never as a desktop's number",
    off_map == "Appgate SDP not moved to desktop 5 on main, and now on above-left's space 77: x", off_map)
  check("WP3: from the drag to B on, a failed round reads where its window is; before it, the window is on A",
    P.round_moved(went, 1) and P.round_moved(went, 3) and not P.round_moved(first_switch, 1)
      and P.round_moved(first_switch, 2) and not P.round_moved({ { kind = "carry" } }, 1))
  check("WP3: a round says the display it went through, by its name; a straight move says so",
    P.route_said(names, "B") == "round through above-left" and P.route_said(names, false) == "straight"
      and P.route_said({}, "X") == "round through screen X", P.route_said(names, "B"))

  -- The landing check a carry's step and a drag's check share.
  check("a held window is read back on the shown space it was taken to", P.landed({ 8 }, 8, 8, "B") == true)
  local _, lwhy = P.landed({ 6 }, 8, 8, "B")
  check("and is not, while it is still on its old space, saying where it is",
    P.landed({ 6 }, 8, 8, "B") == nil and lwhy == "the window is on {6}, not space 8 alone, and screen B shows space 8",
    tostring(lwhy))
  check("nor when its display shows another space", P.landed({ 8 }, 10, 8, "B") == nil)
  local _, uwhy = P.landed(nil, nil, 8, "B", "windowSpaces failed", "activeSpaceOnScreen failed")
  check("a read that failed is said with its error, never as nil",
    uwhy == "the window is on what could not be read: windowSpaces failed, not space 8 alone, and screen B shows what could"
      .. " not be read: activeSpaceOnScreen failed", tostring(uwhy))

  -- A panel whose shown desktop was not read may be the way round: the move
  -- fails on that read, as it does on A's own, with no fix.
  local blind_panel = zeopit(10, 9)
  blind_panel.active.A, blind_panel.active_error = nil, { A = "activeSpaceOnScreen(A) failed" }
  local bp, bpwhy, bpfix = P.move_legs(blind_panel, appgate)
  check("WP3: a panel whose desktop could not be read, and no other way round: the move fails on the read, with no fix",
    bp == nil and bpfix == nil and bpwhy == "Appgate SDP not moved to desktop 5 on main: Parallels Desktop and Screen"
      .. " Sharing are full screen between desktop 6 and desktop 5, and what above-right shows could not be read:"
      .. " activeSpaceOnScreen(A) failed", tostring(bpwhy))
  local untyped = zeopit(10, 9)
  untyped.active.A = 99
  local _, uwhy2 = P.move_legs(untyped, appgate)
  check("WP3: and a panel showing a space the last observe gave no type is not taken for a full-screen one",
    string.find(tostring(uwhy2), "what above-right shows could not be read: it shows space 99, which the last observe gave"
      .. " no type", 1, true) ~= nil, tostring(uwhy2))
  check("desk ordinals count user desktops only", P.desktop_ordinal(rhad_order, types, 7) == 6
    and P.desktop_ordinal(rhad_order, types, 423) == nil and P.desktop_ordinal(rhad_order, types, 99) == nil)
  check("a desktop is said by its ordinal, else the desk's, else as a space id",
    P.desktop_label(rhad, "L", 7) == "desktop 6" and P.desktop_label(rhad, "L", 99, 4) == "desktop 4"
      and P.desktop_label(rhad, "L", 99) == "space 99", P.desktop_label(rhad, "L", 99))

  -- STca1b7f9: displays and apps named as a person reads them, one rule each.
  local nw = base_world()
  table.insert(nw.screens, { uuid = "SCREEN-B", name = "Built-in Retina Display", spaces = {},
    frame = { x = 0, y = 825, w = 1800, h = 1144 }, full_frame = { x = 0, y = 825, w = 1800, h = 1169 } })
  local dn = P.display_names(base_desk(), nw, {})
  check("display names: the desk's name for a display it matches, a screen's own for one it does not describe",
    dn["SCREEN-A"] == "left" and dn["SCREEN-B"] == "Built-in Retina Display",
    tostring(dn["SCREEN-A"]) .. " / " .. tostring(dn["SCREEN-B"]))
  local unnamed = base_desk()
  unnamed.displays[1].name = nil
  local un = P.display_names(unnamed, nw, {})
  check("display names: a desk display with no name is 'display N', as a step's display says it",
    un["SCREEN-A"] == "display 1", tostring(un["SCREEN-A"]))
  local unmatched = base_desk()
  unmatched.displays[1].match = { uuid = "NOPE", name = "NOPE", size = "1x1", position = "nowhere" }
  local um = P.display_names(unmatched, nw, {})
  check("display names: a desk that matches no screen leaves every screen its own name",
    um["SCREEN-A"] == "VY229HF" and um["SCREEN-B"] == "Built-in Retina Display", tostring(um["SCREEN-A"]))
  check("app label: a display name, else the bundle, never an empty name",
    P.app_label("Mail", "com.apple.mail") == "Mail" and P.app_label("", "com.apple.mail") == "com.apple.mail"
      and P.app_label(nil, "com.apple.mail") == "com.apple.mail", P.app_label("", "com.apple.mail"))
  local aw = base_world()
  aw.screens[1].spaces[1].windows[1].app_name = "Mail"
  aw.screens[1].spaces[1].windows[2].app_name = ""
  local by_space, by_window = P.named_apps(aw)
  check("named apps: each space's named windows by app and title, and each window's app, by the one fallback",
    by_space[11][1].app == "Mail" and by_space[11][1].title == "Inbox" and by_space[11][2].app == "com.apple.Safari"
      and by_window[101] == "Mail" and by_window[102] == "com.apple.Safari" and by_window[103] == "com.microsoft.VSCode",
    tostring(by_window[101]) .. " / " .. tostring(by_window[102]))

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
  -- AT-ad94d40b.3 (STca1b7f9 acceptance.md) cites this arm.
  -- Issue I4eacd29: the reason reaches Finished, so it names the app and
  -- never the title, which the op keeps for the log.
  check("unmovable's reason names the app and no window title, and the op keeps the title for the log",
    uops and string.find(uops[1].reason, "com.microsoft.VSCode is on 2 spaces", 1, true) == 1
      and not string.find(uops[1].reason, "arngz.lua - Utilz", 1, true) and uops[1].title == "arngz.lua - Utilz",
    uops and uops[1] and uops[1].reason)
  local named = base_world()
  table.insert(space(named, 1).windows, space(named, 2).windows[1])
  table.insert(named.screens[1].spaces, { id = 13, ordinal = 3, type = "user", uuid = "SPACE-13", windows = {} })
  space(named, 2).windows[1].app_name = "Visual Studio Code"
  local nops = P.plan(d, named, {})
  check("unmovable's reason names the app by its display name where observe read one",
    nops and nops[1] and string.find(nops[1].reason, "Visual Studio Code is on 2 spaces", 1, true) == 1,
    nops and nops[1] and nops[1].reason)
  check("unmovable's reason says the target as the toast's lines do: desktop <n> on <A>",
    uops and uops[1] and string.find(uops[1].reason, "and not on desktop 3 on left;", 1, true) ~= nil,
    uops and uops[1] and uops[1].reason)

  -- Issue Ib12d894: a desk display with no name, which the validator allows,
  -- is said by its place in the desk, never "display nil", in each reason.
  local function unnamed_desk()
    local u = base_desk()
    table.insert(u.displays[1].spaces, { apps = { { app = "com.microsoft.VSCode", window = "Utilz", layout = "0,0 12x8" } } })
    table.remove(u.displays[1].spaces[2].apps, 1)
    u.displays[1].name = nil
    return u
  end
  local zops = P.plan(unnamed_desk(), base_world(), {})
  local said_all, nil_said = {}, false
  for _, op in ipairs(zops or {}) do
    said_all[#said_all + 1] = op.op .. ": " .. tostring(op.reason)
    if string.find(tostring(op.reason), "nil", 1, true) then nil_said = true end
  end
  local joined = table.concat(said_all, " | ")
  check("Ib12d894: an unnamed desk display is 'display 1' in a create's, a move's and a place's reason, never nil",
    zops and not nil_said and kinds(zops) == "create_space,move,place"
      and string.find(joined, "create_space: display 1 needs 3 spaces and has 2", 1, true) ~= nil
      and string.find(joined, "not space 3 of display 1", 1, true) ~= nil
      and string.find(joined, "to 0,0 12x8 on display 1", 1, true) ~= nil, joined)
  local uz = P.plan(unnamed_desk(), far, {})
  check("Ib12d894: and unmovable's reason says it on its own, as 'on <A>' does: desktop 3 on display 1",
    uz and uz[1] and string.find(uz[1].reason, "and not on desktop 3 on display 1;", 1, true) ~= nil,
    uz and uz[1] and uz[1].reason)
  check("Ib12d894: a display is named by its name, else its place, on its own or after the word display",
    P.desk_display_name(base_desk(), 1) == "left" and P.desk_display_phrase(base_desk(), 1) == "display left"
      and P.desk_display_name(unnamed_desk(), 1) == "display 1" and P.desk_display_phrase(unnamed_desk(), 1) == "display 1")
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

-- ------------------------------------------------------------- the report

print("report")
do
  local d = base_desk()
  local function r(op, path, status, reason, bundle, note)
    return { op = op, path = path, status = status, reason = reason, bundle = bundle, note = note }
  end
  local lines, code = P.apply_report(d, {})
  check("every entry placed exits 0, one line per entry", code == 0 and #lines == 3 and string.find(lines[1], ": placed$") ~= nil,
    table.concat(lines, " | "))
  lines, code = P.apply_report(d, {
    r("move", "displays[0].spaces[1].apps[0]", "done"), r("place", "displays[0].spaces[1].apps[0]", "done"),
  })
  check("a done move reads as moved and placed", code == 0 and string.find(lines[3], "moved and placed", 1, true) ~= nil, lines[3])
  -- A not_running result as execute returns it: uncounted, as plan marked
  -- it, with the name LaunchServices gave (ST6d8eed9 AC-35219619.2).
  local function nr(path, bundle, name)
    return { op = "not_running", path = path, status = "not_running", bundle = bundle, uncounted = true, app_name = name,
      reason = bundle .. " is not running, and apply does not launch apps" }
  end
  local tally
  lines, code, tally = P.apply_report(d, { nr("displays[0].spaces[0].apps[1]", "com.apple.Safari", "Safari") })
  check("an app that is not running reads as not running, exits 0, and is tallied and named, never first",
    code == 0 and string.find(lines[2], ": not running: ", 1, true) ~= nil and tally.not_running == 1
      and tally.not_running_apps == "Safari" and tally.first == nil and tally.first_outcome == nil, lines[2])
  lines, code, tally = P.apply_report(d, { nr("displays[0].spaces[0].apps[1]", "com.apple.Safari"),
    r("place", "displays[0].spaces[1].apps[0]", "failed", "the window refused its size") })
  check("beside a counted failure, the failure is first and the app with no name says its bundle",
    code == 1 and tally.first_outcome == "failed" and tally.not_running_apps == "com.apple.Safari", tostring(tally.first))
  lines, code, tally = P.apply_report(d, {})
  check("a run with every app running carries no not_running_apps", tally.not_running == 0 and tally.not_running_apps == nil,
    tostring(tally.not_running_apps))
  -- An unseen result as execute returns it, with the mark plan set: uncounted
  -- unless a window read failed when it was planned (issue 0132).
  local function unseen(path, counted)
    return { op = "unseen", path = path, status = "unseen", reason = "no window", uncounted = not counted }
  end
  local function said(c, ls) return "exit " .. tostring(c) .. ": " .. table.concat(ls, " | ") end
  lines, code = P.apply_report(d, { unseen("displays[0].spaces[0].apps[0]") })
  check("an entry no window matched, unseen and uncounted, is said and exits 0 (issue 0132)",
    code == 0 and string.find(lines[1], "unseen: no window", 1, true) ~= nil, said(code, lines))
  lines, code = P.apply_report(d, { unseen("displays[0].spaces[0].apps[0]", true) })
  check("an unseen entry plan counted, since a window read failed, exits 1 (issue 0132)",
    code == 1 and string.find(lines[1], "unseen: no window", 1, true) ~= nil, said(code, lines))
  local refused = "the window refused its size"
  local _, ahead = P.apply_report(d, { r("place", "displays[0].spaces[0].apps[0]", "failed", refused),
    unseen("displays[0].spaces[1].apps[0]") })
  local _, behind = P.apply_report(d, { unseen("displays[0].spaces[0].apps[0]"),
    r("place", "displays[0].spaces[1].apps[0]", "failed", refused) })
  check("a failed entry exits 1 before or after an uncounted unseen one (issue 0132)",
    ahead == 1 and behind == 1, "before: exit " .. tostring(ahead) .. ", after: exit " .. tostring(behind))
  lines, code = P.apply_report(d, { unseen("displays[0].spaces[0].apps[0]"),
    r("gone", "displays[0].spaces[0].apps[0]", "failed", "quit") })
  check("a counted result after an uncounted unseen one on the same entry still exits 1 (issue 0132)",
    code == 1, said(code, lines))
  -- Every entry unseen and uncounted, as the planner gives them for the base
  -- world with every window closed, beside a phase that failed.
  local closed = base_world()
  for _, sp in ipairs(closed.screens[1].spaces) do sp.windows = {} end
  local every, premise = {}, true
  for _, op in ipairs(P.plan(d, closed, {}) or {}) do
    premise = premise and op.op == "unseen" and op.uncounted == true
    every[#every + 1] = { op = op.op, path = op.path, bundle = op.bundle, status = "unseen", reason = op.reason,
      uncounted = op.uncounted }
  end
  local entries = #every
  every[#every + 1] = { op = "phase", phase = "organise", status = "failed", reason = "organise: boom" }
  lines, code = P.apply_report(d, every)
  premise = premise and entries > 0 and #lines == entries + 1
  for i = 1, entries do premise = premise and string.find(lines[i], ": unseen: ", 1, true) ~= nil end
  check("every entry unseen and uncounted cannot hide a failed phase: exit 1 (issue 0132)",
    code == 1 and premise and lines[#lines] == "phase: failed: organise: boom", said(code, lines))
  lines, code = P.apply_report(d, {
    r("move", "displays[0].spaces[1].apps[0]", "failed", "the readback shows it on space 11"),
    r("place", "displays[0].spaces[1].apps[0]", "failed", "its move failed"),
  })
  check("a move whose readback disagreed is failed, with why, exit 1",
    code == 1 and string.find(lines[3], "failed: the readback shows it on space 11", 1, true) ~= nil, lines[3])
  lines, code = P.apply_report(d, { r("phase", nil, "failed", "replan: the plan after creating refused: x") })
  local any_placed = false
  for _, l in ipairs(lines) do
    if string.find(l, ": placed", 1, true) or string.find(l, "and placed", 1, true) then any_placed = true end
  end
  check("when the engine could not go on, no entry reads as placed, and the exit is 1",
    code == 1 and not any_placed and string.find(lines[1], "not finished: replan: the plan after", 1, true) ~= nil, lines[1])
  -- What run_phase emits for a phase that failed after things changed, from
  -- a phase whose name is also an op kind: still blanket.
  for _, phase in ipairs({ "prepare", "unseen", "replan", "organise" }) do
    lines, code = P.apply_report(d, { { op = "phase", phase = phase, status = "failed", reason = phase .. ": boom" } })
    check("a failed " .. phase .. " phase after things changed leaves no entry placed, exit 1",
      code == 1 and string.find(lines[1], "failed: not finished: " .. phase .. ": boom", 1, true) ~= nil, lines[1])
  end
  lines, code = P.apply_report(d, { r("gone", "displays[0].spaces[0].apps[1]", "failed", "quit") })
  check("an app that quit while the run moved its windows reads as failed, exit 1",
    code == 1 and string.find(lines[2], "failed: quit", 1, true) ~= nil, lines[2])
  lines, code = P.apply_report(d, { r("restore", nil, "note", "focus left where it is") })
  check("a note is said and leaves the exit at 0, with no path printed for it",
    code == 0 and #lines == 4 and lines[4] == "restore: note: focus left where it is", lines[4])
  lines, code = P.apply_report(d, { r("create_space", "displays[0].spaces[2]", "failed", "addSpaceToScreen returned false") })
  check("a failed op that serves no one entry is its own line, and lifts the exit",
    code == 1 and #lines == 4 and string.find(lines[4], "create_space", 1, true) ~= nil, lines[4])

  -- issue 0133: a window held at the app's own size is placed, and says so.
  -- WHAT THIS DOES NOT PIN: the note's wording and its numbers are the
  -- engine's, built in exec_place, which loads only under Hammerspoon. These
  -- checks supply the note and prove apply_report renders it and counts it
  -- against nothing; they would stay green if the engine's wording changed.
  -- AT-03.2's split is why there is no arm for the engine side.
  local own = "placed at the app's own size, 375x667"
  lines, code = P.apply_report(d, { r("place", "displays[0].spaces[0].apps[0]", "done", nil, nil, own) })
  -- AT-01.3 (ST0032), its first check.
  check("a placed entry with a note says it in brackets and exits 0",
    code == 0 and lines[1] == "com.apple.mail (displays[0].spaces[0].apps[0]): placed (" .. own .. ")", lines[1])
  -- The byte-identical guard: with no note, the line must end where it did.
  lines, code = P.apply_report(d, { r("place", "displays[0].spaces[0].apps[0]", "done") })
  check("a placed entry with no note is unchanged, ending at the outcome",
    code == 0 and string.find(lines[1], ": placed$") ~= nil, lines[1])
  -- A note must not mask a failure elsewhere on the desk.
  lines, code = P.apply_report(d, {
    r("place", "displays[0].spaces[0].apps[0]", "done", nil, nil, own),
    r("place", "displays[0].spaces[1].apps[0]", "failed", "the readback shows it elsewhere"),
  })
  -- AT-01.3 (ST0032), its second check.
  check("a note beside a failed entry still exits 1, and both are said",
    code == 1 and string.find(lines[1], own, 1, true) ~= nil
      and string.find(lines[3], "failed: the readback shows it elsewhere", 1, true) ~= nil,
    table.concat(lines, " | "))
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
  check("the same app twice on a display carries a window pattern on each, its magic escaped, anchored at neither end",
    docs and docs.window == "Docs %(draft%) 100%%", docs and docs.window)
  local members = {}
  for _, a in ipairs(s1) do members[#members + 1] = a.app .. "|" .. tostring(a.window) .. "|" .. a.layout end
  table.sort(members)
  check("the first desktop holds mail bare, both Safari windows by pattern, and the full-screen TV filed after it",
    table.concat(members, " ") == "com.apple.Safari|Docs %(draft%) 100%%|4,0 4x4 com.apple.Safari|News|4,0 4x4"
      .. " com.apple.TV|nil|fullscreen com.apple.mail|nil|0,0 4x4", table.concat(members, " "))
  check("and that escaped pattern matches its own title",
    docs and string.find("Docs (draft) 100%", docs.window) ~= nil)
  check("an app with one window in the world carries no pattern", by_app["com.apple.mail"] ~= nil)
  -- ic's W4: these counts leave hv's line for each space and go to the run
  -- log, so P.desk_from_world returns them as data, and its notes say none.
  local _, _, _, counts = P.desk_from_world(world, { name = "zeop2" })
  local total = { minimized = 0, unnamed = 0, everywhere = 0, own = 0 }
  for _, c in ipairs(counts or {}) do
    for k in pairs(total) do total[k] = total[k] + (c[k] or 0) end
  end
  check("minimized, unnamed, every-space and Hammerspoon's windows are not recorded, and counted for the run log (ic's W4)",
    total.minimized > 0 and total.unnamed > 0 and total.everywhere > 0 and total.own > 0
      and not has_note(notes, "Accessibility could not name") and not has_note(notes, " minimized"), notes_text(notes))
  local spaces = 0
  for _, s in ipairs(world.screens) do spaces = spaces + #s.spaces end
  local first = (counts or {})[1] or {}
  local two_gaps = { { space = first.space }, { space = first.space } }
  local lines = P.space_lines(counts, two_gaps)
  check("space lines: one for each space, in hv's words, with 'not recorded' only where that space has a gap,"
      .. " counted from the gaps (ic's W3, W4)",
    #lines == spaces and #(counts or {}) == spaces
      and lines[1] == string.format("%s space %d: %d named, %d recorded, %d not recorded", first.display, first.ordinal,
        first.named, first.recorded, #two_gaps)
      and lines[2] == string.format("%s space %d: %d named, %d recorded", counts[2].display, counts[2].ordinal,
        counts[2].named, counts[2].recorded), table.concat(lines, " | "))
  local report = P.with_space_lines(counts, {}, notes)
  check("discover's report: the space lines first, then the notes (ic's W4)",
    #report == spaces + #notes and report[1] == P.space_lines(counts, {})[1] and report[spaces + 1] == notes[1],
    table.concat(report, " | "))
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

-- ------------------------------------------------- off-display windows (issue 0134)

print("off-display windows")
do
  local function entry_for(d, bundle)
    for _, disp in ipairs(d and d.displays or {}) do
      for _, sp in ipairs(disp.spaces or {}) do
        for _, a in ipairs(sp.apps or {}) do if a.app == bundle then return a end end
      end
    end
  end
  -- The control: where the base world puts it, mail is on its display and is
  -- recorded exactly as it always was. Without this, a predicate that excluded
  -- everything would pass the check below.
  local on_desk, on_notes = P.desk_from_world(base_world(), { name = "t" })
  check("a window on its display is still recorded, and nothing is said about it",
    entry_for(on_desk, "com.apple.mail") ~= nil
      and not has_note(on_notes, "lies mostly outside this display"))
  -- Run 69's case: a window 1920 points left of the display's origin, which
  -- snap_axis would clamp into the edge cell, and which the next apply then
  -- fails because the cell is narrower than the app will go.
  local w = base_world()
  w.screens[1].spaces[1].windows[1].frame = { x = -1920, y = 25, w = 600, h = 800 }
  local off_desk, off_notes = P.desk_from_world(w, { name = "t" })
  -- AT-02.2 (ST0032)
  check("a window lying mostly off its display is not recorded at all",
    entry_for(off_desk, "com.apple.mail") == nil, render(entry_for(off_desk, "com.apple.mail")))
  check("and discover says why, rather than snapping it into the edge cell",
    has_note(off_notes, "is not recorded: it lies mostly outside this display's usable area"),
    notes_text(off_notes))
  check("the window that stayed on the display is still recorded beside it",
    entry_for(off_desk, "com.apple.Safari") ~= nil)
end

-- ------------------------- windows lost mid-run (STca1b7f9 WP6, I7fce35c)

print("windows lost mid-run")
do
  -- VSCode ran when apply began, and a read now says it does not, while its
  -- window 103 from the start is still listed: hv's false gone of 13:51Z.
  local before = P.app_windows(base_world())
  check("WP6: the windows named at the start, by id, each with its app's key",
    before[101] == "com.apple.mail" and before[102] == "com.apple.safari" and before[103] == "com.microsoft.vscode",
    tostring(before[103]))
  local opts = { running_before = { ["com.microsoft.vscode"] = true }, windows_before = before }
  local w = base_world()
  w.apps_running = { "com.apple.mail", "com.apple.Safari" }
  local ops = P.plan(base_desk(), w, opts)
  -- AT-322a6511.3 (STca1b7f9 acceptance.md) cites this arm.
  check("WP6: an app read as not running while its window from the start is still listed is planned as running:"
    .. " its window is claimed and already in place, so nothing, and never gone", ops and kinds(ops) == "", ops_text(ops))
  -- A second VSCode window from the start, with a higher id, still listed:
  -- the lowest is the one named.
  local two = base_world()
  two.apps_running = { "com.apple.mail", "com.apple.Safari" }
  table.insert(space(two, 1).windows, win(150, "com.microsoft.VSCode", "notes - Utilz", 0, 25, 600, 800))
  local opts2 = { running_before = opts.running_before, windows_before = P.app_windows(two) }
  local taken = P.taken_in(two, opts2)
  check("WP6: it is taken as running by its lowest window from the start still listed",
    taken["com.microsoft.vscode"] == 103, tostring(taken["com.microsoft.vscode"]))
  local gone_w = base_world()
  gone_w.apps_running = { "com.apple.mail", "com.apple.Safari" }
  table.remove(space(gone_w, 2).windows, 1)
  local gops = P.plan(base_desk(), gone_w, opts)
  check("WP6: one with no window from the start still listed is gone, as before", gops and kinds(gops) == "gone",
    ops_text(gops))

  -- The retry rule: the filter's failure is a read that could not be made.
  local ran, failed = { window_filter = "ran" }, { window_filter = "failed: hs/uielement.lua:134" }
  local takes, why = P.retry_takes(ran, failed)
  -- AT-322a6511.1 (STca1b7f9 acceptance.md) cites this arm.
  check("WP6: a retry from a world whose window filter failed does not replace a plan from one where it ran, saying why",
    takes == false and why == "its window filter failed: hs/uielement.lua:134", tostring(why))
  local pairs_taken = { P.retry_takes(ran, ran), P.retry_takes(failed, ran), P.retry_takes(failed, failed),
    P.retry_takes(ran, {}) }
  check("WP6: a retry from a world where it ran replaces the plan in hand, as one does when both failed, and one"
    .. " whose windows were not listed at all is left to plan's own refusal",
    pairs_taken[1] == true and pairs_taken[2] == true and pairs_taken[3] == true and pairs_taken[4] == true,
    table.concat({ tostring(pairs_taken[1]), tostring(pairs_taken[2]), tostring(pairs_taken[3]),
      tostring(pairs_taken[4]) }, " / "))
end

-- --------------------------------------------- space creation (issue 0135)

print("space creation")
do
  -- Hammerspoon's own strings, taken from runs 35 and 32 of hv's menuz log
  -- rather than invented, since the classifier matches on them.
  -- STca1b7f9 WP6 narrows 0135 for this one reason: four tries in one
  -- callback never once rode it out (0135's run 35, hv's two runs of 23 Nov),
  -- and each try asks the Dock to open Mission Control again while it may
  -- still be opening. So it is its own kind, which stops the tries.
  check("WP6: a Dock that did not open Mission Control is its own kind, whatever the case",
    P.space_error_kind("unable to get Mission Control data from the Dock") == "dock"
      and P.space_error_kind("Unable To Get Mission Control Data From The Dock") == "dock")
  check("WP6: the Dock's kind and a gone display end the tries at once; any other reason does not",
    P.space_error_final("unable to get Mission Control data from the Dock")
      and P.space_error_final("no display with specified id found")
      and not P.space_error_final("the Dock is not answering") and not P.space_error_final(nil))
  local dwords, dfix = P.create_failure("unable to get Mission Control data from the Dock")
  check("WP6: its words say the Dock did not open Mission Control for Hammerspoon, and its fix is to add the desktop by hand",
    dwords == "the Dock did not open Mission Control for Hammerspoon (unable to get Mission Control data from the Dock)"
      and dfix == "add the desktop in Mission Control by hand, then run it again", tostring(dwords) .. " / " .. tostring(dfix))
  local owords, ofix2 = P.create_failure("no display with specified id found")
  check("WP6: any other create failure is said as Hammerspoon gave it, with no fix",
    owords == "no display with specified id found" and ofix2 == nil, tostring(owords))
  -- AT-03.1 (ST0032)
  check("a display the plan named and which is gone cannot be retried into existence",
    P.space_error_kind("no display with specified id found") == "gone")
  -- The deliberate default, which is the whole reason this is a function and
  -- not an inline comparison: the cheap mistake is to wait.
  check("an unrecognised reason is transient, as are an empty one and none at all",
    P.space_error_kind("something new from a later macOS") == "transient"
      and P.space_error_kind("") == "transient"
      and P.space_error_kind(nil) == "transient")
  check("the match does not depend on the case Hammerspoon used",
    P.space_error_kind("No Display With Specified Id Found") == "gone")
end

-- ------------------------------------- which desk the screens are (ST0032/04)

print("detect")
do
  -- Desks and worlds bound by uuid, which is match_displays' first and
  -- simplest route, so these cases test detect's rule and not the matching's.
  local function desk_of(...)
    local displays = {}
    for _, u in ipairs({ ... }) do
      displays[#displays + 1] = { name = u, match = { uuid = u } }
    end
    return { displays = displays }
  end
  -- A frame on every screen because candidates_text, which a refusal builds,
  -- asks size_of for one and size_of indexes full_frame or frame.
  local function world_of(...)
    local screens = {}
    for _, u in ipairs({ ... }) do
      screens[#screens + 1] = { uuid = u, name = u, position = "main",
        frame = { x = 0, y = 0, w = 1200, h = 800 } }
    end
    return { screens = screens }
  end
  local function named(name, desk) return { name = name, desk = desk } end
  local function reported(lines, text)
    for _, l in ipairs(lines or {}) do if string.find(l, text, 1, true) then return true end end
    return false
  end

  local laptop_only = named("rhad", desk_of("U-LAP"))
  local two_screens = named("homere", desk_of("U-LAP", "U-BIG"))

  local name, kind = P.detect({ laptop_only }, world_of("U-LAP"))
  -- AT-04.3 (ST0032)
  check("one desk covering the one screen present is the desk", name == "rhad" and kind == "one",
    tostring(name) .. "/" .. tostring(kind))

  -- THE RULE THIS WHOLE FEATURE TURNS ON. match_displays binds rhad's one
  -- display to the laptop whatever else is plugged in, so without the count
  -- rhad would be the answer at every site. It describes one of the two
  -- screens here, so it does not fit and homere does.
  --
  -- Every expected number below is derived from the fixture it counts, never
  -- written down: the world and the desk lists are held in locals and their
  -- lengths build the expected text.
  local report, both
  local two_world = world_of("U-LAP", "U-BIG")
  name, kind, report = P.detect({ laptop_only, two_screens }, two_world)
  -- AT-04.2 (ST0032)
  check("a desk describing fewer screens than are present does not win",
    name == "homere" and kind == "one", tostring(name) .. "/" .. tostring(kind))
  check("and the report says how many of the screens present it described",
    reported(report, string.format("rhad: it describes %d of the %d screen(s) present",
      #laptop_only.desk.displays, #two_world.screens)), table.concat(report, " | "))

  name, kind, report = P.detect({ laptop_only }, two_world)
  check("no desk covering the screens present is none, with a reason",
    name == nil and kind == "none"
      and reported(report, string.format("no desk fits the %d screen(s) present", #two_world.screens)),
    tostring(name) .. "/" .. tostring(kind) .. " " .. table.concat(report, " | "))

  local twin = named("zeopit", desk_of("U-LAP", "U-BIG"))
  local fits
  both = { two_screens, twin }
  name, kind, report, fits = P.detect(both, two_world)
  check("two desks describing the same screens is several, naming both, and picks neither",
    name == nil and kind == "several" and #fits == #both and reported(report, "homere, zeopit"),
    tostring(name) .. "/" .. tostring(kind) .. " " .. table.concat(report, " | "))

  name, kind = P.detect(both, two_world, { current = "zeopit" })
  -- AT-04.4 (ST0032)
  check("and the current desk decides when it is one of them",
    name == "zeopit" and kind == "current", tostring(name) .. "/" .. tostring(kind))
  name, kind = P.detect(both, two_world, { current = "rhad" })
  check("a current desk that does not fit decides nothing",
    name == nil and kind == "several", tostring(name) .. "/" .. tostring(kind))

  -- A desk whose display matches nothing keeps match_displays' own words,
  -- rather than detect inventing a second vocabulary for the same fact.
  name, kind, report = P.detect({ named("hockenbury", desk_of("U-GONE")) }, world_of("U-LAP"))
  -- AT-04.5 (ST0032)
  check("a desk whose display matches no screen is reported in the matching's own words",
    name == nil and kind == "none" and reported(report, "matches no screen"),
    table.concat(report, " | "))

  check("no desks at all is none, not an error",
    select(2, P.detect({}, world_of("U-LAP"))) == "none")
  -- The exact cover is a count, so 0 == 0 would make a desk with no displays
  -- fit a world with no screens and be answered as the desk. Held out
  -- explicitly rather than left to the arithmetic.
  -- AT-04.1 (ST0032): the 0 == 0 guard.
  check("a desk with no displays does not fit a world with no screens",
    select(2, P.detect({ named("empty", { displays = {} }) }, world_of())) == "none")
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
  check("an app with a window on each of two displays gets a pattern on both, the contained title anchored at its end",
    table.concat(patterns, " ") == "Inbox %- 2 messages Inbox$", table.concat(patterns, " "))
  check("and the pattern discover wrote for the contained title misses the title that contains it",
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
        if a.window and string.find("News", a.window) then news = news + 1 end
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
    slack ~= nil and slack.app == "com.tinyspeck.slackmacgap" and slack.window == "Slack",
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

-- ST0028: a pinned title survives a moving prefix. Run 8's two iTerm titles
-- (16 Oct 2026, hv's machine): Claude Code's working glyph in front of the
-- session name, and a shell at its prompt. AT-01.1.
do
  local world = F.moving_titles_world()
  local desk, notes = P.desk_from_world(world, {})
  local by_title = {}
  for _, d in ipairs(desk.displays) do
    for _, sp in ipairs(d.spaces) do
      for _, a in ipairs(sp.apps) do
        if a.app == "com.googlecode.iterm2" then by_title[#by_title + 1] = tostring(a.window) end
      end
    end
  end
  table.sort(by_title)
  check("AT-01.1: discover pins each title's core, escaped, anchored at neither end",
    table.concat(by_title, " ") == "utilz%-dc zsh", table.concat(by_title, " "))
  local dc, sh = by_title[1], by_title[2]
  check("AT-01.1: the session's pattern matches its title with another glyph in front, and with none",
    dc ~= nil and string.find("\u{2733} utilz-dc", dc) ~= nil and string.find("utilz-dc", dc) ~= nil
      and string.find("\u{25D1} utilz-dc", dc) ~= nil, tostring(dc))
  check("AT-01.1: the shell's pattern matches its title as it was",
    sh ~= nil and string.find("-zsh", sh) ~= nil, tostring(sh))
  local ok, why = only_places(desk, world)
  check("AT-01.2: that desk plans against its own world with nothing but snapping places", ok, why)
  check("AT-01.3: the report names every window it pinned, with its title and its pattern",
    has_note(notes, 'com.googlecode.iterm2 "\u{25D1} utilz-dc" pinned as "utilz%-dc"')
      and has_note(notes, 'com.googlecode.iterm2 "-zsh" pinned as "zsh"'), notes_text(notes))
  check("AT-01.3: and names the Safari windows the discover world pins",
    has_note(notes, 'com.apple.Safari "News" pinned as "News"'), notes_text(notes))
end

-- ST0028: the core that would claim another window tightens. AT-01.2.
do
  local world = F.colliding_cores_world()
  local desk, notes = P.desk_from_world(world, {})
  local got = {}
  for _, d in ipairs(desk.displays) do
    for _, sp in ipairs(d.spaces) do
      for _, a in ipairs(sp.apps) do
        if a.app == "com.googlecode.iterm2" then got[#got + 1] = tostring(a.window) end
      end
    end
  end
  table.sort(got)
  check("AT-01.2: cores that collide fall to the exact title; a title all decoration takes the exact title",
    table.concat(got, " ") == "^%-%-%-$ ^\u{25D1} notes$ ^\u{2733} notes$", table.concat(got, " "))
  local ok, why = only_places(desk, world)
  check("AT-01.2: that desk plans against its own world with nothing but snapping places", ok, why)
  check("AT-01.2: two windows with one title stay unrecorded, and are said",
    select(2, string.gsub(notes_text(notes), 'its title "build" does not tell it', "")) == 2, notes_text(notes))
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


-- ------------------------------------------------------------- own sizes (ST0034)

-- A size an app holds its window at, remembered (issue 0138). Safari's window
-- (102) is wanted in a 600x800 cell at 600,25; here its app holds it at
-- 375x667, Appgate's measured size. Each arm calls through `own`, so at the
-- base, where none of these functions exists, every arm fails on its own
-- rather than the first one ending the run.
print("own sizes")
local function own(name, ...)
  if type(P[name]) ~= "function" then return nil, "P." .. name .. " does not exist" end
  local ok, a, b = pcall(P[name], ...)
  if not ok then return nil, tostring(a) end
  return a, b
end
local CELL = { x = 600, y = 25, w = 600, h = 800 }
local HELD = { w = 375, h = 667 }
local function held_world(frame)
  local w = base_world()
  space(w, 1).windows[2].frame = frame or { x = 600, y = 25, w = 375, h = 667 }
  return w
end
local function record(bundle, want, size)
  return { bundle = bundle or "com.apple.safari", want = want or { w = 600, h = 800 }, size = size or { w = 375, h = 667 } }
end
local function plan_with(world, records)
  local ok, ops = pcall(P.plan, base_desk(), world, { own_sizes = records })
  if not ok then return nil end
  return ops
end

-- AT-01.1 (ST0034)
do
  local ops = plan_with(held_world(), nil)
  check("own sizes: with no record, a window at its app's size is placed, as today", kinds(ops) == "place", ops_text(ops))
  ops = plan_with(held_world(), { record() })
  check("own sizes: at its cells' origin at a recorded size, it is rechecked, not placed",
    kinds(ops) == "recheck", ops_text(ops))
  local op = ops and ops[1]
  check("own sizes: the recheck carries the cell's frame and the size the window is at",
    op and op.window == 102 and op.frame and op.frame.w == CELL.w and op.frame.h == CELL.h
      and op.size and op.size.w == HELD.w and op.size.h == HELD.h, ops_text(ops))
  ops = plan_with(held_world({ x = 600, y = 25, w = 376, h = 666 }), { record() })
  check("own sizes: a size within the slack of the record is rechecked", kinds(ops) == "recheck", ops_text(ops))
  ops = plan_with(held_world({ x = 600, y = 25, w = 400, h = 600 }), { record() })
  check("own sizes: a size matching neither the record nor the cell is placed", kinds(ops) == "place", ops_text(ops))
  ops = plan_with(held_world({ x = 650, y = 25, w = 375, h = 667 }), { record() })
  check("own sizes: away from its cells' origin it is placed whatever is recorded", kinds(ops) == "place", ops_text(ops))
  ops = plan_with(held_world(), { record("com.example.other") })
  check("own sizes: a record for another app is not this one's", kinds(ops) == "place", ops_text(ops))
  ops = plan_with(held_world(), { record(nil, { w = 500, h = 800 }) })
  check("own sizes: a record for another cell size is not this one's", kinds(ops) == "place", ops_text(ops))
  ops = plan_with(held_world(), { { bundle = "com.apple.safari", size = { w = 375, h = 667 } } })
  check("own sizes: a record of the wrong shape is passed over, not read", kinds(ops) == "place", ops_text(ops))
  local w = held_world()
  local safari = table.remove(space(w, 1).windows, 2)
  table.insert(space(w, 2).windows, safari)
  ops = plan_with(w, { record() })
  check("own sizes: a window on the wrong space is moved and placed whatever is recorded",
    kinds(ops) == "move,place", ops_text(ops))
  check("own sizes: a recheck of a window on a desktop not shown needs the hand, as a place does",
    P.needs_hand({ { op = "recheck", window = 103 } }, base_world()) == true)
end

-- AT-01.2 (ST0034)
do
  local note = own("own_size_note", "in place", { w = 375.4, h = 667 })
  check("own sizes: the note says the size, rounded", note == "in place at the app's own size, 375x667", tostring(note))
  local ops = plan_with(held_world(), { record() }) or {}
  check("own sizes: diff exits 0 when the only op is a recheck", P.plan_exit(ops) == 0, ops_text(ops))
  local mixed = plan_with(held_world(), { record() }) or {}
  mixed[#mixed + 1] = { op = "place", window = 101, frame = CELL, reason = "r" }
  check("own sizes: and 1 when anything else would change", P.plan_exit(mixed) == 1, ops_text(mixed))
  local lines = P.plan_report(ops)
  check("own sizes: diff reads no change first, then the window in place at its app's own size",
    #lines == 2 and lines[1] == "no change: this machine already matches the desk"
      and string.find(lines[2] or "", "window 102 in place at the app's own size, 375x667 (displays[0].spaces[0].apps[1]): ", 1, true) == 1,
    table.concat(lines, " | "))
  local report, code = P.apply_report(base_desk(), { { op = "recheck", path = "displays[0].spaces[0].apps[1]",
    bundle = "com.apple.Safari", status = "done", note = note } })
  check("own sizes: apply says a rechecked window is placed, noting its app's own size, and exits 0",
    code == 0 and string.find(report[2] or "", "): placed (in place at the app's own size, 375x667)", 1, true) ~= nil,
    table.concat(report or {}, " | "))
end

-- AT-01.3 (ST0034)
do
  local function result(op, status, got)
    return { op = op, bundle = "com.apple.Safari", status = status, want = { x = 600, y = 25, w = 600, h = 800 },
      readback = { frame = got } }
  end
  local AT_OWN = { x = 600, y = 25, w = 375, h = 667 }
  local recs, changed = own("own_sizes_after", {}, { result("place", "done", AT_OWN) })
  check("own sizes: an own_size readback adds its record, keyed on the app however it is spelt",
    recs and #recs == 1 and recs[1].bundle == "com.apple.safari" and recs[1].want.w == 600 and recs[1].size.w == 375
      and changed == true, render(recs))
  recs, changed = own("own_sizes_after", { record() }, { result("recheck", "done", CELL) })
  check("own sizes: a placed readback removes it, the app no longer holding its size",
    recs and #recs == 0 and changed == true, render(recs))
  -- Each read back at the held size, so only the gate under test keeps it out.
  recs, changed = own("own_sizes_after", {}, { result("recheck", "failed", AT_OWN) })
  check("own sizes: a failed result leaves the records as they were", recs and #recs == 0 and changed == false, render(recs))
  recs, changed = own("own_sizes_after", {}, { result("move", "done", AT_OWN) })
  check("own sizes: a result that is not a place or recheck changes nothing", recs and #recs == 0 and changed == false, render(recs))
  recs, changed = own("own_sizes_after", { record(nil, nil, { w = 400, h = 700 }) }, { result("place", "done", AT_OWN) })
  check("own sizes: a new size for the same app and cell replaces the old one",
    recs and #recs == 1 and recs[1].size.w == 375 and changed == true, render(recs))
  local other = record("com.example.other", { w = 100, h = 100 }, { w = 50, h = 50 })
  recs = own("own_sizes_after", { other }, { result("place", "done", AT_OWN) })
  check("own sizes: records for other apps are kept untouched",
    recs and #recs == 2 and recs[1] == other, render(recs))
  local once = own("own_sizes_after", {}, { result("place", "done", AT_OWN) })
  local twice, again = own("own_sizes_after", once, { result("place", "done", AT_OWN) })
  check("own sizes: merging the same results twice gives the same records, unchanged",
    twice and #twice == 1 and again == false, render(twice))
end

-- ---------------------------------- extra desktops (ST6d8eed9 WP 88504807)

print("extra desktops")

-- The base world with its screen's desktops in ORDER: 11 and 12 are the
-- base's, with their windows, and any other id is a new empty desktop. Each
-- is numbered as observe numbers it, and SHOWN (11 unless given) is the one
-- its display shows.
local function world_of(order, shown)
  local w = base_world()
  local by = {}
  for _, sp in ipairs(w.screens[1].spaces) do by[sp.id] = sp end
  local spaces = {}
  for i, id in ipairs(order) do
    local sp = by[id] or { id = id, type = "user", uuid = "SPACE-" .. id, windows = {} }
    sp.ordinal = i
    sp.active = id == (shown or 11)
    spaces[i] = sp
  end
  w.screens[1].spaces = spaces
  return w
end

-- The base desk with a third desktop that names no app, so a display needs
-- three, and two empty desktops can compete for one removal.
local function three_desk()
  local d = base_desk()
  table.insert(d.displays[1].spaces, { name = "spare", apps = {} })
  return d
end

local function removed_ids(ops)
  local out = {}
  for _, op in ipairs(ops or {}) do
    if op.op == "remove_space" then out[#out + 1] = tostring(op.space) end
  end
  return table.concat(out, ",")
end

-- AT-88504807.1 (ST6d8eed9 acceptance.md) cites the arms from here to the
-- two removals'. The new-desktop-first case: at a plug-in, macOS puts a new
-- empty desktop first on the monitor, before the desktops it carries back.
-- Removing it lines them up with the desk. Removing the one at the end would
-- leave every window a desktop off its own.
do
  local ops, err = P.plan(three_desk(), world_of({ 20, 11, 12, 21 }), {})
  check("extra: the new empty desktop first is removed, not the empty one at the end", removed_ids(ops) == "20",
    err or ops_text(ops))
  check("extra: and with it gone every window is on its own desktop, so nothing else is planned",
    kinds(ops) == "remove_space", ops_text(ops))
  local op = ops and ops[1] or {}
  check("extra: a removal names its screen, its desktop's id, its place among the display's desktops, and the desk path",
    op.screen == "SCREEN-A" and op.space == 20 and op.ordinal == 1 and op.path == "displays[0]"
      and string.find(tostring(op.reason), "display left needs 3 spaces and has 4; space 1 is empty", 1, true) ~= nil,
    string.format("%s %s %s %s %s", tostring(op.screen), tostring(op.space), tostring(op.ordinal), tostring(op.path),
      tostring(op.reason)))
end

-- The end case: a new empty desktop after the desk's.
do
  local ops, err = P.plan(base_desk(), world_of({ 11, 12, 20 }), {})
  check("extra: an empty desktop at the end is removed, and nothing else is planned",
    removed_ids(ops) == "20" and kinds(ops) == "remove_space" and ops[1].ordinal == 3, err or ops_text(ops))
end

-- A tie: either removal leaves every entry at home.
do
  local ops, err = P.plan(three_desk(), world_of({ 11, 12, 20, 21 }), {})
  check("extra: a tie removes the later desktop", removed_ids(ops) == "21", err or ops_text(ops))
  local shown, serr = P.plan(three_desk(), world_of({ 11, 12, 20, 21 }, 21), {})
  check("extra: a tie keeps the shown desktop, though it is the later one", removed_ids(shown) == "20",
    serr or ops_text(shown))
end

-- Two removals from three empty desktops: each candidate set is whole, and
-- the removals go later first, so none moves the place of one still to come.
do
  local ops, err = P.plan(three_desk(), world_of({ 20, 11, 12, 21, 22 }), {})
  check("extra: two of three empty desktops removed, the first and the later of the tie, later first",
    removed_ids(ops) == "22,20" and ops[1].ordinal == 5 and ops[2].ordinal == 1, err or ops_text(ops))
end

-- AT-88504807.2 (ST6d8eed9 acceptance.md) cites the arms from here to the
-- unmatched screen's.
do
  local ops = P.plan(base_desk(), base_world(), {})
  check("extra: a display with no excess removes nothing", ops and #ops == 0, ops_text(ops))
  local held = world_of({ 11, 12, 20 })
  held.screens[1].spaces[3].windows = { win(104, "com.apple.Notes", "Notes", 0, 25, 300, 300) }
  local hops, herr = P.plan(base_desk(), held, {})
  check("extra: a desktop with a window only it lists is kept, as a note that counts against nothing",
    kinds(hops) == "extra" and hops[1].uncounted == true and hops[1].count == 1
      and string.find(hops[1].reason, "display left keeps 1 desktop(s) more than the 2 the desk names;"
        .. " desktops 1, 2, 3 hold windows", 1, true) ~= nil,
    herr or (hops and hops[1] and hops[1].reason) or ops_text(hops))
  local report = P.plan_report(hops)
  check("extra: diff says no change, then the kept desktop, and exits 0",
    P.plan_exit(hops) == 0 and string.find(report[1] or "", "no change", 1, true) == 1
      and string.find(report[2] or "", "keep 1 extra space(s) on SCREEN-A (displays[0]): ", 1, true) == 1,
    table.concat(report or {}, " | "))
  -- Part of the excess removed, the rest kept: both said.
  local part = world_of({ 11, 12, 20, 21 })
  part.screens[1].spaces[4].windows = { win(104, "com.apple.Notes", "Notes", 0, 25, 300, 300) }
  local pops, perr = P.plan(base_desk(), part, {})
  check("extra: an excess with one empty desktop removes it and keeps the rest, said",
    kinds(pops) == "remove_space,extra" and pops[1].space == 20 and pops[2].count == 1, perr or ops_text(pops))
end

-- A window on every space holds no desktop.
do
  local sticky = world_of({ 11, 12, 20 })
  local nc = win(900, "com.apple.notificationcenterui", "Notification Center", 0, 0, 10, 10)
  for _, sp in ipairs(sticky.screens[1].spaces) do sp.windows[#sp.windows + 1] = nc end
  local ops, err = P.plan(base_desk(), sticky, {})
  check("extra: a desktop whose one window is on every space is empty, and removed", removed_ids(ops) == "20",
    err or ops_text(ops))
end

-- A full-screen space is not a desktop.
do
  local fs = base_world()
  table.insert(fs.screens[1].spaces, { id = 99, ordinal = 3, type = "fullscreen", uuid = "SPACE-99", windows = {} })
  local ops, err = P.plan(base_desk(), fs, {})
  check("extra: a full-screen space is never removed, nor counted as an extra desktop", ops and #ops == 0,
    err or ops_text(ops))
end

-- A screen the desk does not match.
do
  local w = base_world()
  table.insert(w.screens, { uuid = "SCREEN-B", name = "Other", primary = false, position = "above",
    frame = { x = 0, y = -800, w = 1200, h = 800 }, full_frame = { x = 0, y = -825, w = 1200, h = 825 },
    spaces = {
      { id = 31, ordinal = 1, type = "user", uuid = "SPACE-31", active = true, windows = {} },
      { id = 32, ordinal = 2, type = "user", uuid = "SPACE-32", windows = {} },
    } })
  local ops, err = P.plan(base_desk(), w, {})
  check("extra: a screen the desk does not match keeps its empty desktops", ops and #ops == 0, err or ops_text(ops))
end

-- AT-88504807.4 (ST6d8eed9 acceptance.md) cites the arms from here to the
-- report's.
do
  local again = P.plan(three_desk(), world_of({ 20, 11, 12, 21 }), { no_remove = true })
  local kept = again and again[#again] or {}
  check("extra: a second plan never removes; it keeps the excess as a note, last",
    removed_ids(again) == "" and kept.op == "extra" and kept.count == 1, ops_text(again))
  -- Desktop 20 first and empty, desktop 12 empty, VS Code with Mail and
  -- Safari on 11: removing 20 leaves two entries home where removing 12
  -- leaves one, and the move to the desk's second desktop is then to 12.
  local w = world_of({ 20, 11, 12 })
  table.insert(w.screens[1].spaces[2].windows, table.remove(w.screens[1].spaces[3].windows, 1))
  local ops, err = P.plan(base_desk(), w, {})
  check("extra: the moves are planned against the world without the removed desktop",
    kinds(ops) == "remove_space,move,place" and ops[1].space == 20 and ops[2].space == 12 and ops[2].ordinal == 2,
    err or ops_text(ops))
  local lines = P.plan_report(ops)
  check("extra: diff says the removal first, in its own words, and counts it as a change",
    string.find(lines[1] or "", "remove empty space 1 of SCREEN-A (displays[0]): display left needs 2 spaces and has 3;"
      .. " space 1 is empty", 1, true) == 1 and P.plan_exit(ops) == 1,
    table.concat(lines or {}, " | "))
end

-- The report counts a removal done.
do
  local _, code, tally = P.apply_report(base_desk(), {
    { op = "remove_space", path = "displays[0]", status = "done" },
    { op = "remove_space", path = "displays[0]", status = "note", reason = "not removed: the proof failed" },
  })
  check("extra: the report counts each removal done, and a removal not done is a note that counts against nothing",
    tally.removed == 1 and code == 0, tostring(tally.removed) .. " / " .. tostring(code))
end

-- What the finished point's extra reads, and what the engine's removal asks.
do
  local unread_world = world_of({ 20, 11, 12, 21 })
  unread_world.screens[1].spaces_error = "spacesForScreen failed"
  check("extra_desktops: the desktops beyond the desk's count on the displays it matches, nil where none match"
    .. " or the read failed",
    P.extra_desktops(base_desk(), world_of({ 20, 11, 12, 21 }), {}) == 2
      and P.extra_desktops(base_desk(), base_world(), {}) == 0
      and P.extra_desktops(base_desk(), nil, {}) == nil
      and P.extra_desktops(base_desk(), unread_world, {}) == nil,
    tostring(P.extra_desktops(base_desk(), world_of({ 20, 11, 12, 21 }), {})))
  check("same_ids: the same ids in the same order, and nothing else",
    P.same_ids({ 1, 2, 3 }, { 1, 2, 3 }) and not P.same_ids({ 1, 2, 3 }, { 1, 3, 2 })
      and not P.same_ids({ 1, 2 }, { 1, 2, 3 }))
  check("removal_place: the next desktop, else the one before, else none",
    P.removal_place({ 1, 2, 3 }, 2) == 3 and P.removal_place({ 1, 2, 3 }, 3) == 2 and P.removal_place({ 1 }, 1) == nil
      and P.removal_place({ 1, 2 }, 9) == nil)
  local done = P.removal_verdict({ 1, 2, 3 }, { 1, 2 }, 3)
  local other, went = P.removal_verdict({ 1, 2, 3 }, { 1, 3 }, 3)
  local none = P.removal_verdict({ 1, 2, 3 }, { 1, 2, 3 }, 3)
  local came_too, _, came = P.removal_verdict({ 1, 2, 3 }, { 1, 2, 7 }, 3)
  check("removal_verdict: exactly the target gone is done, another gone is other, no change is none, one come is other",
    done == "done" and other == "other" and went[1] == 2 and none == "none" and came_too == "other" and came[1] == 7,
    table.concat({ tostring(done), tostring(other), tostring(none), tostring(came_too) }, " / "))
  local empty = P.empty_by({}, function() return 0 end)
  local alone, alone_why = P.empty_by({ 5 }, function() return 1 end)
  local elsewhere = P.empty_by({ 5 }, function() return 3 end)
  local unread, unread_why = P.empty_by({ 5 }, function() return nil, "boom" end)
  check("empty_by: no window, or windows on other spaces too, is empty; a window on it alone, or one unread, is not",
    empty and not alone and alone_why == "window 5 is on it alone" and elsewhere and not unread
      and string.find(tostring(unread_why), "could not be read: boom", 1, true) ~= nil,
    tostring(alone_why) .. " / " .. tostring(unread_why))
end

-- ------------------------------ the window list (WP 88504807, hv decision 49)
--
-- macOS 27 gives each desktop system windows of its own, listed on it alone
-- and at layers other than 0 (cc's read r3, 26 Nov 2026). The ids here stand
-- for them; LAYER_0 is the layer of a window a person places.

print("the window list")

local BACKDROP, MENU_BAR, STRIP = -2147483624, 24, -2147483602
local LAYER_0 = 0

-- windows.js's text: its header, then "<id> <layer> <pid>" for each pair given,
-- each owned by OWNER.
local OWNER = 88
local function list_text(pairs_)
  local lines = { P.WINDOW_LIST_HEADER }
  for _, p in ipairs(pairs_) do lines[#lines + 1] = p[1] .. " " .. p[2] .. " " .. OWNER end
  return table.concat(lines, "\n") .. "\n"
end

-- A desktop's own system windows, which Accessibility does not name.
local function system_windows(first)
  return { { id = first, named = false }, { id = first + 1, named = false }, { id = first + 2, named = false } }
end

do
  local free, why = P.parse_window_list(list_text({ { 501, BACKDROP }, { 502, MENU_BAR }, { 503, STRIP }, { 104, LAYER_0 } }))
  check("window list: every id at a layer other than 0 is free, and a layer-0 window is not",
    free and table.concat(free, ",") == "501,502,503", why or table.concat(free or {}, ","))
  local none, nwhy = P.parse_window_list(list_text({}))
  check("window list: a list with no free window is a list, not a failure", none and #none == 0, nwhy)
  local bad, bwhy = P.parse_window_list("error: CGWindowListCopyWindowInfo gave no list")
  check("window list: text with no header is not a list, and says what it printed",
    bad == nil and string.find(tostring(bwhy), "did not print a window list: error:", 1, true) ~= nil, bwhy)
  local odd, owhy = P.parse_window_list(P.WINDOW_LIST_HEADER .. "\n501 x\n")
  check("window list: a line that is not '<id> <layer>' fails the list", odd == nil
    and string.find(tostring(owhy), "not '<id> <layer> <pid> <w> <h> <onscreen> <alpha>': 501 x", 1, true) ~= nil, owhy)
  local silent, swhy = P.parse_window_list(nil)
  check("window list: no text at all is not a list", silent == nil and swhy == "windows.js printed nothing", swhy)
end

-- A world whose new desktop 20 lists only its own system windows, and every
-- desktop's are free in the window list.
local function world_with_system_windows()
  local w = world_of({ 11, 12, 20 })
  local first = { [11] = 601, [12] = 611, [20] = 621 }
  w.free_windows = {}
  for _, sp in ipairs(w.screens[1].spaces) do
    for _, sw in ipairs(system_windows(first[sp.id])) do
      sp.windows[#sp.windows + 1] = sw
      w.free_windows[#w.free_windows + 1] = sw.id
    end
  end
  return w, w.screens[1].spaces[3]
end

do
  local ops, err = P.plan(base_desk(), world_with_system_windows(), {})
  check("window list: a new desktop that lists only its own free system windows is empty, and removed",
    removed_ids(ops) == "20" and kinds(ops) == "remove_space", err or ops_text(ops))

  local unfreed = world_with_system_windows()
  unfreed.free_windows = nil
  local kops, kerr = P.plan(base_desk(), unfreed, {})
  check("window list: with no window list, the same desktop's system windows hold it (the live run's fault)",
    kinds(kops) == "extra", kerr or ops_text(kops))

  local unseen, sp20 = world_with_system_windows()
  sp20.windows[#sp20.windows + 1] = { id = 705, named = false }
  local uops, uerr = P.plan(base_desk(), unseen, {})
  check("window list: an unseen app's layer-0 window, which Accessibility cannot name, holds its desktop",
    kinds(uops) == "extra" and string.find(uops[1].reason, "desktops 1, 2, 3 hold windows", 1, true) ~= nil,
    uerr or ops_text(uops))

  local floating, fsp = world_with_system_windows()
  fsp.windows[#fsp.windows + 1] = { id = 706, named = false }
  floating.free_windows[#floating.free_windows + 1] = 706
  local fops, ferr = P.plan(base_desk(), floating, {})
  check("window list: a desktop that holds only a floating window (a layer other than 0) is empty, and removed",
    removed_ids(fops) == "20", ferr or ops_text(fops))

  local unread = world_with_system_windows()
  unread.free_windows, unread.free_error = nil, "osascript windows.js ended by signal 14: "
  local rops, rerr = P.plan(base_desk(), unread, {})
  check("window list: a list that could not be read removes nothing, and the kept desktop says why",
    kinds(rops) == "extra" and string.find(rops[1].reason, "desktops not removed: " .. P.NO_WINDOW_LIST .. ": osascript windows.js ended by signal 14",
      1, true) ~= nil, rerr or ops_text(rops))

  local again = P.plan(base_desk(), unread, { no_remove = true })
  check("window list: a second plan, which never removes, does not blame the window list",
    kinds(again) == "extra" and not string.find(again[1].reason, P.NO_WINDOW_LIST, 1, true), ops_text(again))

  local free = P.free_set({ free_windows = { 5 } })
  check("empty_by: a free id holds no desktop, though it is listed there alone",
    P.empty_by({ 5 }, function() return 1 end, free) and not P.empty_by({ 5, 6 }, function() return 1 end, free))
end

-- ------------------ windows on desktops not shown (cc's visit-note, 26 Nov)
--
-- After a Hammerspoon restart, a window on a desktop not shown is named only
-- once its desktop has been shown. The base world with Safari's window 102
-- unnamed on desktop 12, which its display does not show.

print("windows on desktops not shown")

local SAFARI = "com.apple.Safari"

local function safari_on_12()
  local w = base_world()
  local sp = w.screens[1].spaces
  table.remove(sp[1].windows, 2)
  table.insert(sp[2].windows, { id = 102, named = false })
  w.layer0_windows = { { bundle = SAFARI, ids = { 102 } } }
  return w
end

local function unseen_op(ops)
  for _, op in ipairs(ops or {}) do
    if op.op == "unseen" then return op end
  end
  return {}
end

do
  local free, owned = P.parse_window_list(P.WINDOW_LIST_HEADER .. "\n501 24 77\n102 0 88\n103 0 88\n")
  check("window list v2: the free ids, and each owner's layer-0 windows",
    free and #free == 1 and free[1] == 501 and owned and owned[88] and table.concat(owned[88], ",") == "102,103"
      and owned[77] == nil, tostring(owned))
  local v1 = P.parse_window_list("arngz-windows 1\n501 24\n")
  check("window list: a version 1 list is not read (windows.js ships beside it)", v1 == nil)

  local w = safari_on_12()
  local ops, err = P.plan(base_desk(), w, {})
  local op = unseen_op(ops)
  check("unseen: a window on a desktop not shown says it is not named yet, and where",
    op.reason == SAFARI .. " is running and its window is not named yet: it is on desktop 2 on"
      .. " display left, which apply shows", err or tostring(op.reason))
  local screens = P.match_displays(base_desk(), w, {})
  local list = P.visit_list(base_desk(), w, screens, ops)
  check("visit: the list holds the desktop not shown that holds the unseen app's window, once",
    #list == 1 and list[1].space == 12 and list[1].place == 2 and list[1].screen == "SCREEN-A"
      and table.concat(list[1].bundles, ",") == SAFARI, tostring(#list))

  local visited = P.plan(base_desk(), safari_on_12(), { visited = { [12] = true } })
  check("unseen: after apply showed the desktop, the entry says so",
    unseen_op(visited).reason == SAFARI .. " is running and its window is on desktop 2 on display left, which arngz"
      .. " showed, and Accessibility still could not name it", tostring(unseen_op(visited).reason))

  local late = P.plan(base_desk(), safari_on_12(), { visit_out_of_time = 20 })
  check("unseen: an app the visit step did not reach stays not named yet, and says the time ran out",
    string.find(tostring(unseen_op(late).reason), "its window is not named yet", 1, true) ~= nil
      and string.find(tostring(unseen_op(late).reason), "this run's 20 s to show desktops ran out first", 1, true) ~= nil,
    tostring(unseen_op(late).reason))

  local failed = P.plan(base_desk(), safari_on_12(), { visit_failed = { ["SCREEN-A"] = "Mission Control refused AXPress" } })
  check("unseen: a desktop whose show failed says apply could not show it, and why (ic's F1)",
    string.find(tostring(unseen_op(failed).reason), "which apply could not show: Mission Control refused AXPress", 1, true)
      ~= nil, tostring(unseen_op(failed).reason))

  local both = P.plan(base_desk(), safari_on_12(), { visited = { [12] = true },
    visit_failed = { ["SCREEN-A"] = "Mission Control refused AXPress" } })
  check("unseen: a desktop shown before a later show on its display failed still says arngz showed it (ic's F1b)",
    string.find(tostring(unseen_op(both).reason), "which arngz showed", 1, true) ~= nil, tostring(unseen_op(both).reason))

  local shown = safari_on_12()
  shown.screens[1].spaces[1].active, shown.screens[1].spaces[2].active = false, true
  local sops = P.plan(base_desk(), shown, {})
  check("visit: a desktop its display shows is not in the list",
    #P.visit_list(base_desk(), shown, P.match_displays(base_desk(), shown, {}), sops) == 0)

  local fs = safari_on_12()
  table.remove(fs.screens[1].spaces[2].windows)
  table.insert(fs.screens[1].spaces, { id = 99, ordinal = 3, type = "fullscreen", uuid = "SPACE-99",
    windows = { { id = 102, named = false } } })
  local fops = P.plan(base_desk(), fs, {})
  check("unseen: a window on a full-screen space says so, and the space is never in the list",
    unseen_op(fops).reason == SAFARI .. " is running and its window is on a full-screen space, which arngz leaves alone"
      and #P.visit_list(base_desk(), fs, P.match_displays(base_desk(), fs, {}), fops) == 0,
    tostring(unseen_op(fops).reason))

  local two = safari_on_12()
  two.apps_running[#two.apps_running + 1] = "com.apple.mail"
  table.remove(two.screens[1].spaces[1].windows, 1)
  table.insert(two.screens[1].spaces[2].windows, { id = 101, named = false })
  two.layer0_windows[#two.layer0_windows + 1] = { bundle = "com.apple.mail", ids = { 101 } }
  local tops = P.plan(base_desk(), two, {})
  local tlist = P.visit_list(base_desk(), two, P.match_displays(base_desk(), two, {}), tops)
  check("visit: two unseen apps on one desktop show it once, with both apps",
    #tlist == 1 and #tlist[1].bundles == 2, tostring(#tlist))

  local plain = P.plan(base_desk(), (function()
    local w2 = safari_on_12()
    w2.layer0_windows = nil
    return w2
  end)(), {})
  check("unseen: with no window list, the entry keeps the words it had",
    string.find(tostring(unseen_op(plain).reason), "no standard window of it on a desktop space could be named", 1, true)
      ~= nil, tostring(unseen_op(plain).reason))
end

-- ------------------------- Save Desk's windows not named (issue I19d4fa6)
--
-- The base world with Safari's window 102 unnamed on desktop 12, which the
-- display does not show, and the window list giving it to Safari.

print("Save Desk's windows not named")

local SAFARI_PID = 88

local function save_world()
  local w = base_world()
  local sp = w.screens[1].spaces
  table.remove(sp[1].windows, 2)
  table.insert(sp[2].windows, { id = 102, named = false })
  w.layer0_owned = { { pid = SAFARI_PID, bundle = "com.apple.Safari", name = "Safari", ids = { 102 } } }
  return w
end

do
  local free, owned = P.parse_window_list(P.WINDOW_LIST_HEADER .. "\n102 0 88 900 545\n103 0 88 1 1\n")
  check("window list: a window smaller than MIN_WINDOW_SIDE is not owned, one a person uses is",
    owned and owned[88] and #owned[88] == 1 and owned[88][1] == 102 and #free == 0, tostring(owned and owned[88]))

  local w = save_world()
  local list = P.discover_visit_list(w)
  check("discover visit: the desktop not shown with the unnamed window of a running app, once",
    #list == 1 and list[1].space == 12 and list[1].place == 2 and list[1].bundles[1] == "com.apple.Safari"
      and list[1].ids["com.apple.Safari"] == 102, tostring(#list))

  local shown = save_world()
  shown.screens[1].spaces[1].active, shown.screens[1].spaces[2].active = false, true
  check("discover visit: a shown desktop is not in the list", #P.discover_visit_list(shown) == 0)

  local named = base_world()
  named.layer0_owned = { { pid = SAFARI_PID, bundle = "com.apple.Safari", name = "Safari", ids = { 102 } } }
  check("discover visit: a window observe named is not in the list", #P.discover_visit_list(named) == 0)

  local fs = save_world()
  table.remove(fs.screens[1].spaces[2].windows)
  table.insert(fs.screens[1].spaces, { id = 99, ordinal = 3, type = "fullscreen", uuid = "SPACE-99",
    windows = { { id = 102, named = false } } })
  check("discover visit: a full-screen space is never in the list", #P.discover_visit_list(fs) == 0)

  local desk = P.desk_from_world(save_world(), { grid = "8x4", name = "x" })
  local gaps = P.discover_gaps(save_world(), desk, { visited = { [12] = true } })
  check("gaps: a window still not named after its desktop was shown is a gap, with its app, desktop and display",
    #gaps == 1 and gaps[1].name == "Safari" and gaps[1].place == 2 and gaps[1].why == P.GAP_SHOWN,
    gaps[1] and P.gap_line(gaps[1]))
  check("gaps: the line in ic's words",
    gaps[1] and P.gap_line(gaps[1]) == "not recorded: Safari on desktop 2 on " .. tostring(gaps[1].display) .. ": " .. P.GAP_SHOWN)
  local failed = P.discover_gaps(save_world(), desk, { failed = { ["SCREEN-A"] = "Mission Control refused AXPress" } })
  check("gaps: a desktop whose show failed says so", failed[1] and failed[1].why
    == "arngz could not show that desktop: Mission Control refused AXPress", failed[1] and failed[1].why)
  local late = P.discover_gaps(save_world(), desk, { out_of_time = 20 })
  check("gaps: a desktop the step did not reach says the time ran out", late[1] and late[1].why == P.GAP_NOT_REACHED)
  local on_shown = save_world()
  on_shown.screens[1].spaces[1].active, on_shown.screens[1].spaces[2].active = false, true
  local sgaps = P.discover_gaps(on_shown, desk, {})
  check("gaps: a window on a desktop already shown says that desktop is shown, not that arngz showed it (ic's W1)",
    sgaps[1] and sgaps[1].why == P.GAP_ON_SHOWN, sgaps[1] and sgaps[1].why)

  check("verdict: no --save prints, no gap saves, --with-gaps saves with gaps, else refused; --force changes none",
    P.save_verdict(gaps, {}) == "print" and P.save_verdict({}, { save = "x" }) == "save"
      and P.save_verdict(gaps, { save = "x", with_gaps = true }) == "save with gaps"
      and P.save_verdict(gaps, { save = "x", force = true }) == "refused")
  local why, fix = P.save_refusal(gaps, "zeopit")
  check("refusal: says how many, once; a gap arngz showed has no step but --with-gaps, and arngz log (ic's R1)",
    why == '1 window could not be named, so desk "zeopit" would leave it out'
      and fix == "run arngz discover --save zeopit --with-gaps to save without it; arngz log names each window",
    tostring(why) .. " / " .. tostring(fix))
  local _, sfix = P.save_refusal(failed, "zeopit")
  check("refusal: a desktop whose show failed is named to show, then --with-gaps (ic's R1)",
    sfix == "show desktop 2 on " .. tostring(failed[1].display) .. ", then Save Desk again, or run arngz discover --save zeopit"
      .. " --with-gaps to save without it", sfix)
  local _, lfix = P.save_refusal({ { cause = "late", place = 1, display = "d" }, gaps[1] }, "zeopit")
  check("refusal: a gap that came late, with one arngz showed, takes Save Desk again; no shown desktop is named",
    lfix == "Save Desk again, or run arngz discover --save zeopit --with-gaps to save without them", lfix)
  local _, mfix = P.save_refusal({ gaps[1], late[1], failed[1] }, "zeopit")
  check("refusal: mixed causes name only the desktops a show can help, once each",
    mfix == "show desktop 2 on " .. tostring(failed[1].display) .. ", then Save Desk again, or run arngz discover --save zeopit"
      .. " --with-gaps to save without them", mfix)

  -- A free window (macOS's own) adds to its space's windows and not to the
  -- ones Accessibility could not name (ic's W4 moved the count to data).
  local counted = save_world()
  local id = counted.screens[1].spaces[2].id
  table.insert(counted.screens[1].spaces[2].windows, { id = 621, named = false })
  counted.free_windows = { 621 }
  local function count_of(world)
    local _, _, _, counts = P.desk_from_world(world, { grid = "8x4", name = "x" })
    for _, c in ipairs(counts or {}) do
      if c.space == id then return c end
    end
  end
  local with_free, without = count_of(counted), count_of(save_world())
  check("counts: a free window (macOS's own) is not counted as one Accessibility could not name",
    with_free and without and with_free.windows == without.windows + 1 and with_free.unnamed == without.unnamed,
    with_free and (tostring(with_free.windows) .. " / " .. tostring(with_free.unnamed)))
end

-- ------------- Save Desk's gaps are windows a person sees (save-note addendum)

print("Save Desk's gaps are windows a person sees")
do
  local free, owned, unseen = P.parse_window_list(P.WINDOW_LIST_HEADER
    .. "\n102 0 88 900 545 1 1.000\n103 0 88 900 545 0 1.000\n104 0 88 900 545 1 0.000\n501 24 77 10 10 0 1.000\n")
  -- The unseen windows are a list of ids in the list's order, as the free
  -- ids are, since the world carries them in apply's and observe's answers
  -- (issue I19d4fa6, hv decision 60).
  check("window list v4: an onscreen window with alpha is seen; one offscreen, or with alpha 0.000, is not (alpha in windows.js's fixed form, vc's N2), as a list of ids",
    free and owned and unseen and unseen[1] == 103 and unseen[2] == 104 and unseen[3] == nil,
    tostring(free and #free))
  local set = P.id_set({ 102, 104 })
  check("id_set: a list of ids becomes the set a reader needs, and no list is an empty set",
    set[102] and set[104] and not set[103] and next(P.id_set(nil)) == nil)
  check("free_set: a world's free ids as a set, and a world with none frees nothing",
    P.free_set({ free_windows = { 501 } })[501] == true and next(P.free_set({})) == nil)
  local _, _, old = P.parse_window_list(P.WINDOW_LIST_HEADER .. "\n102 0 88 900 545\n")
  check("window list: a line with no onscreen state counts as seen, the safe side", old and old[1] == nil)
  local v3, v3why = P.parse_window_list("arngz-windows 3\n102 0 88 900 545\n")
  check("window list: a version 3 list is refused by its header", v3 == nil
    and string.find(tostring(v3why), "did not print a window list: arngz-windows 3", 1, true) ~= nil, v3why)

  -- Safari owns 102 (the real window) and 103 (a helper) on desktop 12, not
  -- shown, and neither is named.
  local function helper_world()
    local w = save_world()
    table.insert(w.screens[1].spaces[2].windows, { id = 103, named = false })
    w.layer0_owned[1].ids = { 102, 103 }
    return w
  end
  local desk = P.desk_from_world(save_world(), { grid = "8x4", name = "x" })
  -- Each stop's unseen windows are a list, as M.visit keeps the parser's.
  local stop_unseen = { 103 }
  local seen, _, left = P.discover_gaps(helper_world(), desk, { visited = { [12] = true }, unseen = { [12] = stop_unseen } })
  check("gaps: on a desktop the visit showed, a helper no person sees is no gap, and the window seen is (F2)",
    #seen == 1 and seen[1].id == 102 and seen[1].cause == "shown", tostring(#seen))
  check("gaps: each gap names its desktop's id, and the helpers left out as not drawn are counted (ic's W4)",
    seen[1] and seen[1].space == 12 and left == #stop_unseen, tostring(left))
  local stop_failed = P.discover_gaps(helper_world(), desk, { visited = { [12] = true }, list_failed = { [12] = "osascript ended" } })
  check("gaps: a stop whose window list could not be read judges nothing: both stay gaps, with its words (vc's note 1)",
    #stop_failed == 2 and stop_failed[1].cause == "list_failed"
      and stop_failed[1].why == P.GAP_LIST_FAILED .. ": osascript ended", tostring(#stop_failed))
  local on_shown = helper_world()
  on_shown.screens[1].spaces[1].active, on_shown.screens[1].spaces[2].active = false, true
  on_shown.unseen_windows = { 103 }
  local sgaps = P.discover_gaps(on_shown, desk, {})
  check("gaps: on a desktop shown at the start, the start's list judges: the helper is no gap (F2)",
    #sgaps == 1 and sgaps[1].id == 102 and sgaps[1].cause == "on_shown", tostring(#sgaps))
  local late = P.discover_gaps(save_world(), desk, {})
  check("gaps: a window on a desktop the visit did not show, with no failure and time to spare, is late, never shown (ic's W1)",
    late[1] and late[1].cause == "late" and late[1].why == P.GAP_LATE, late[1] and late[1].why)

  local hidden = helper_world()
  hidden.layer0_owned[1].hidden = true
  local hgaps, hid = P.discover_gaps(hidden, desk, { visited = { [12] = true }, unseen = { [12] = { 102, 103 } } })
  check("gaps: a hidden app's windows no person sees are no gaps, and its name is kept once for the report (ic's R2)",
    #hgaps == 0 and #hid == 1 and hid[1] == "Safari", tostring(#hgaps) .. " / " .. tostring(#hid))
  check("report: the line for windows left out names the hidden apps (ic's R2)", P.left_out_line(hid)
    == "left out, not counted as gaps: windows of hidden apps whose windows Accessibility could not name (Safari);"
      .. " show them and Save Desk again to record them", P.left_out_line(hid))
  local _, none = P.discover_gaps(helper_world(), desk, { visited = { [12] = true }, unseen = { [12] = { 103 } } })
  check("report: no line when no hidden app's window was left out", P.left_out_line(none) == nil)
  -- Safari hidden, with its window 104 named on desktop 11 and its helpers
  -- unseen on desktop 12 (vc's F3, ic's rule: any desktop).
  local named_elsewhere = helper_world()
  named_elsewhere.layer0_owned[1].hidden = true
  table.insert(named_elsewhere.screens[1].spaces[1].windows, { id = 104, bundle = "com.apple.Safari", named = true })
  local _, quiet = P.discover_gaps(named_elsewhere, desk,
    { visited = { [12] = true }, unseen = { [12] = { 102, 103 } } })
  check("report: a hidden app with a window named, on any desktop, gives no line, though its helpers are unseen (vc's F3)",
    P.left_out_line(quiet) == nil, P.left_out_line(quiet))
end

-- ------------------- the end mark the engine draws (hv decision 53)

print("the end mark the engine draws")
do
  check("mark: an ok answer is done, with problems or without",
    P.mark_end_words({ status = "ok", exit = 0 }) == P.MARK_DONE and P.mark_end_words({ status = "ok", exit = 1 }) == P.MARK_DONE)
  check("mark: a refusal is stopped: refused", P.mark_end_words({ status = "error", kind = "refused" }) == P.MARK_REFUSED)
  check("mark: any other answer, or none, is stopped: error",
    P.mark_end_words({ status = "error", kind = "error" }) == P.MARK_ERROR and P.mark_end_words(nil) == P.MARK_ERROR)
end

print(string.format("plan_test: %d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
